Import-Module Carbon
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

$serviceHome = 'C:/postgres_exporter'
$serviceName = 'postgres_exporter'
$serviceUsername = "NT SERVICE\$serviceName"

# download and install.
# see https://github.com/prometheus-community/postgres_exporter/releases
# renovate: datasource=github-releases depName=prometheus-community/postgres_exporter
$archiveVersion = '0.15.0'
$archiveUrl = "https://github.com/prometheus-community/postgres_exporter/releases/download/v$archiveVersion/postgres_exporter-$archiveVersion.windows-amd64.zip"
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
mkdir $serviceHome | Out-Null
Get-ChocolateyUnzip -FileFullPath $archivePath -Destination $serviceHome
$archiveTempPath = Resolve-Path $serviceHome\postgres_exporter-*
Move-Item $archiveTempPath\* $serviceHome
Remove-Item $archiveTempPath
Remove-Item $archivePath

# install the service.
choco install -y nssm
nssm install $serviceName "$serviceHome/postgres_exporter.exe"

# setup the service account.
$result = sc.exe sidtype $serviceName unrestricted
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe sidtype failed with $result"
}

# create and protect the logs sub-directory.
mkdir $serviceHome/logs | Out-Null
Disable-CAclInheritance $serviceHome/logs
Grant-CPermission $serviceHome/logs SYSTEM FullControl
Grant-CPermission $serviceHome/logs Administrators FullControl
Grant-CPermission $serviceHome/logs $serviceUsername FullControl

# protect the registry key that will contain secret environment variables.
$serviceParametersKey = "HKLM:\System\CurrentControlSet\Services\$serviceName\Parameters"
$serviceParametersKeyAcl = New-Object System.Security.AccessControl.RegistrySecurity
$serviceParametersKeyAcl.SetAccessRuleProtection($true, $false)
@(
    'SYSTEM'
    'Administrators'
) | ForEach-Object {
    $serviceParametersKeyAcl.AddAccessRule((
        New-Object `
            System.Security.AccessControl.RegistryAccessRule(
                $_,
                'FullControl',
                'ContainerInherit,ObjectInherit',
                'None',
                'Allow')))
}
$serviceParametersKeyAcl.AddAccessRule((
    New-Object `
        System.Security.AccessControl.RegistryAccessRule(
                $serviceUsername,
                'ReadKey',
                'ContainerInherit,ObjectInherit',
                'None',
                'Allow')))
Set-Acl $serviceParametersKey $serviceParametersKeyAcl

# configure the service.
nssm set $serviceName Start SERVICE_AUTO_START
nssm set $serviceName AppRotateFiles 1
nssm set $serviceName AppRotateOnline 1
nssm set $serviceName AppRotateSeconds 86400
nssm set $serviceName AppRotateBytes 1048576
nssm set $serviceName AppStdout $serviceHome\logs\service-stdout.log
nssm set $serviceName AppStderr $serviceHome\logs\service-stderr.log
nssm set $serviceName AppParameters `
    '--web.listen-address=localhost:9187'
nssm set $serviceName AppEnvironmentExtra `
    'DATA_SOURCE_NAME=postgres://postgres:postgres@localhost?sslmode=disable'

# configure the service account.
$result = sc.exe config $serviceName obj= $serviceUsername
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}
$result = sc.exe failure $serviceName reset= 0 actions= restart/1000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure failed with $result"
}

# start the service.
Start-Service $serviceName

# give it a try.
(Invoke-RestMethod 'http://localhost:9187/metrics') -split '\r?\n' | Where-Object {$_ -match 'pg_exporter_'}
