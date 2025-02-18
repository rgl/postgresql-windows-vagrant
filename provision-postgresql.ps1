Import-Module Carbon
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

# install dependencies.
# NB you can see which version of MSVC++ was used to compile
#    postgres by running:
#       psql -c 'select version()' postgres
#    which returns something like:
#       PostgreSQL 16.4, compiled by Visual C++ build 1941, 64-bit
#    that build 1941 is for:
#       MSVC++ 14.41 _MSC_VER == 1941 (Visual Studio 2022 version 17.11).
#    see https://en.wikipedia.org/wiki/Microsoft_Visual_C%2B%2B
choco install -y vcredist140

# the default postgres superuser username and password.
# see https://www.postgresql.org/docs/16/libpq-envars.html
$env:PGUSER = 'postgres'
$env:PGPASSWORD = 'postgres'

$serviceHome = 'C:/postgresql'
$serviceName = 'postgresql'
$serviceUsername = "NT SERVICE\$serviceName"
$dataPath = "$serviceHome/data"

function initdb {
    &"$serviceHome/bin/initdb.exe" @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

function pg_ctl {
    &"$serviceHome/bin/pg_ctl.exe" @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

function psql {
    &"$serviceHome/bin/psql.exe" -v ON_ERROR_STOP=1 -w @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

# download and install binaries.
# see https://www.enterprisedb.com/download-postgresql-binaries
$archiveUrl = 'https://get.enterprisedb.com/postgresql/postgresql-16.4-2-windows-x64-binaries.zip'
$archiveHash = 'bb46c3004f0e1fa7b48cd20f44d3138c7ab8d5f1fc102e620f92d0efe0f21c1b'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Output "Downloading from $archiveUrl..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Output "Installing binaries at $serviceHome..."
Get-ChocolateyUnzip -FileFullPath $archivePath -Destination $serviceHome
Move-Item "$serviceHome\pgsql\*" $serviceHome
rmdir "$serviceHome\pgsql"
Remove-Item $archivePath

# see https://www.postgresql.org/docs/16/event-log-registration.html
# see the available log names with:
#       Get-WinEvent -ListLog * | Sort-Object LogName | Format-Table LogName
# see the providers that write to a specific log with:
#       (Get-WinEvent -ListLog Application).ProviderNames | Sort-Object
#       (Get-WinEvent -ListLog Security).ProviderNames | Sort-Object
# see the available provider names with:
#       Get-WinEvent -ListProvider * | Sort-Object Name | Format-Table Name
Write-Output 'Registering the PostgreSQL event log provider...'
regsvr32.exe /s "$serviceHome\lib\pgevent.dll" | Out-String -Stream
if ($LASTEXITCODE) {
    throw "regsvr32.exe failed with exit code $LASTEXITCODE"
}

Write-Output "Installing the $serviceName service..."
pg_ctl `
    register `
    -N $serviceName `
    -D $dataPath `
    -S auto `
    -w
$result = sc.exe sidtype $serviceName unrestricted
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe sidtype failed with $result"
}
$result = sc.exe config $serviceName obj= $serviceUsername
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}

Write-Output "Initializing the database cluster at $dataPath..."
mkdir $dataPath | Out-Null
Disable-CAclInheritance $dataPath
Grant-CPermission $dataPath $env:USERNAME FullControl
Grant-CPermission $dataPath $serviceUsername FullControl
initdb `
    --username=$env:PGUSER `
    --auth-host=trust `
    --auth-local=reject `
    --encoding=UTF8 `
    --locale=en `
    -D $dataPath

Write-Output "Starting the $serviceName service..."
Start-Service $serviceName

Write-Host "Setting the $env:PGUSER user password..."
psql -c "alter role $env:PGUSER login password '$env:PGPASSWORD'" postgres

Write-Host 'Switching from trust to md5 authentication method...'
Stop-Service $serviceName
Set-Content -Encoding ascii "$dataPath\pg_hba.conf" (
    (Get-Content "$dataPath\pg_hba.conf") `
        -replace '^(#?host\s+.+\s+)trust.*','$1md5'
)

Write-Host 'Allowing external connections made with the md5 authentication method...'
@'

# allow md5 authenticated connections from any other address.
#
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
'@ `
    | Out-File -Append -Encoding ascii "$dataPath\pg_hba.conf"

# see https://www.postgresql.org/docs/16/libpq-ssl.html
Write-Host 'Enabling ssl...'
mkdir -Force "$env:APPDATA/postgresql" | Out-Null
Copy-Item c:/vagrant/shared/postgresql-example-ca/postgresql-example-ca-crt.pem "$env:APPDATA/postgresql/root.crt"
Copy-Item c:/vagrant/shared/postgresql-example-ca/postgresql.example.com-crt.pem "$dataPath/server.crt"
Copy-Item c:/vagrant/shared/postgresql-example-ca/postgresql.example.com-key.pem "$dataPath/server.key"
Set-Content -Encoding ascii "$dataPath\postgresql.conf" (
    (Get-Content "$dataPath\postgresql.conf") `
        -replace '^#?(ssl\s+.+?\s+).+','$1on' `
        -replace '^#?(ssl_ciphers\s+.+?\s+).+','$1''HIGH:!aNULL'''
)

Write-Host 'Configuring the listen address...'
Set-Content -Encoding ascii "$dataPath\postgresql.conf" (
    (Get-Content "$dataPath\postgresql.conf") `
        -replace '^#?(listen_addresses\s+.+?\s+).+','$1''0.0.0.0'''
)

Write-Host 'Creating the firewall rule to allow inbound TCP/IP access to the PostgreSQL port 5432...'
New-NetFirewallRule `
    -Name 'POSTGRESQL-In-TCP' `
    -DisplayName 'PostgreSQL (TCP-In)' `
    -Direction Inbound `
    -Enabled True `
    -Protocol TCP `
    -LocalPort 5432 `
    | Out-Null

Write-Output "Starting the $serviceName service..."
Start-Service $serviceName

Write-Output 'Installing the adminpack extension...'
psql -c 'create extension adminpack' postgres

Write-Output 'Showing pg version, connection information, users and databases...'
# see https://www.postgresql.org/docs/16/functions-info.html
psql -c 'select version()' postgres
psql -c 'select current_user, current_database(), inet_client_addr(), inet_client_port(), inet_server_addr(), inet_server_port(), pg_backend_pid(), pg_postmaster_start_time()' postgres
psql -c '\du' postgres
psql -l
