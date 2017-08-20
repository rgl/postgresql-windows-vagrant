# install dependencies.
choco install -y vcredist2013

# the default postgres superuser username and password.
# see https://www.postgresql.org/docs/9.6/static/libpq-envars.html
$env:PGUSER = 'postgres'
$env:PGPASSWORD = 'postgres'

$serviceHome = 'C:/pgsql'
$serviceName = 'pgsql'
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
$archiveUrl = 'https://get.enterprisedb.com/postgresql/postgresql-9.6.4-1-windows-x64-binaries.zip'
$archiveHash = '15a963bd02f54fca9049c9270455d1d74f22674e921a3805b211695fd1a18c3e'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Output "Downloading from $archiveUrl..."
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Output "Installing binaries at $serviceHome..."
Expand-Archive $archivePath -DestinationPath $serviceHome
Move-Item "$serviceHome\pgsql\*" $serviceHome
rmdir "$serviceHome\pgsql"
Remove-Item $archivePath

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

# see https://www.postgresql.org/docs/9.6/static/libpq-ssl.html
Write-Host 'Enabling ssl...'
mkdir -Force "$env:APPDATA/postgresql" | Out-Null
Copy-Item c:/vagrant/shared/pgsql-example-ca/pgsql-example-ca-crt.pem "$env:APPDATA/postgresql/root.crt"
Copy-Item c:/vagrant/shared/pgsql-example-ca/pgsql.example.com-crt.pem "$dataPath/server.crt"
Copy-Item c:/vagrant/shared/pgsql-example-ca/pgsql.example.com-key.pem "$dataPath/server.key"
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
# see https://www.postgresql.org/docs/9.6/static/functions-info.html
psql -c 'select version()' postgres
psql -c 'select current_user, current_database(), inet_client_addr(), inet_client_port(), inet_server_addr(), inet_server_port(), pg_backend_pid(), pg_postmaster_start_time()' postgres
psql -c '\du' postgres
psql -l
