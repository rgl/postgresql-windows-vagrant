# install dependencies.
# NB you can see which version of MSVC++ was used to compile
#    postgres by running:
#       psql -c 'select version()' postgres
#    which returns something like:
#       PostgreSQL 11.0, compiled by Visual C++ build 1914, 64-bit
#    that build 1800 is for:
#       MSVC++ 14.14 _MSC_VER == 1914 (Visual Studio 2017 version 15.7).
#    see https://en.wikipedia.org/wiki/Microsoft_Visual_C%2B%2B
choco install -y vcredist2017

# the default postgres superuser username and password.
# see https://www.postgresql.org/docs/11/libpq-envars.html
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
$archiveUrl = 'https://get.enterprisedb.com/postgresql/postgresql-11.0-1-windows-x64-binaries.zip'
$archiveHash = '73b892ec919cc6437cd546c28cd732710ed9275bcb08d2a35a12c4736bb50640'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Output "Downloading from $archiveUrl..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Output "Installing binaries at $serviceHome..."
Expand-Archive $archivePath -DestinationPath $serviceHome
Move-Item "$serviceHome\pgsql\*" $serviceHome
rmdir "$serviceHome\pgsql"
Remove-Item $archivePath

# postgresql 11.0 was failing with "exit code -1073741515" error because
# libwinpthread-1.dll was not found, this will copy it from git.
if (!(Test-Path "$serviceHome\bin\libwinpthread-1.dll")) {
    Copy-Item 'C:\Program Files\Git\mingw64\bin\libwinpthread-1.dll' "$serviceHome\bin"
}

# see https://www.postgresql.org/docs/11/event-log-registration.html
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
Disable-AclInheritance $dataPath
Grant-Permission $dataPath $env:USERNAME FullControl
Grant-Permission $dataPath $serviceUsername FullControl
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

# see https://www.postgresql.org/docs/11/libpq-ssl.html
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
# see https://www.postgresql.org/docs/11/functions-info.html
psql -c 'select version()' postgres
psql -c 'select current_user, current_database(), inet_client_addr(), inet_client_port(), inet_server_addr(), inet_server_port(), pg_backend_pid(), pg_postmaster_start_time()' postgres
psql -c '\du' postgres
psql -l
