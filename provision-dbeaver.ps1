# install the PostgreSQL JDBC driver.
$archiveUrl = 'http://central.maven.org/maven2/org/postgresql/postgresql/42.2.2/postgresql-42.2.2.jar'
$archiveHash = '1996524026a3027853f3932e8639ef813807d1b63fe14832f410fffa4274fa70'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:USERPROFILE\.dbeaver-drivers\$archiveName"
Write-Host "Downloading $archiveName..."
mkdir -Force (Split-Path -Parent $archivePath) | Out-Null
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}

# install DBeaver.
choco install -y dbeaver

# configure DBeaver.
$pgjdbcHome = "$env:USERPROFILE\.dbeaver-drivers"
$workspaceHome = "$env:USERPROFILE\.dbeaver4"
$metadataHome = "$workspaceHome\.metadata"
$pluginsHome = "$metadataHome\.plugins"
$projectHome = "$workspaceHome\General"
mkdir -Force "$pluginsHome\org.jkiss.dbeaver.core",$projectHome | Out-Null
Copy-Item provision-dbeaver-drivers.xml "$pluginsHome\org.jkiss.dbeaver.core\drivers.xml"
Copy-Item provision-dbeaver-data-sources.xml "$projectHome\.dbeaver-data-sources.xml"
