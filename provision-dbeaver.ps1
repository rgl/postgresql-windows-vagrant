# install the PostgreSQL JDBC driver.
$archiveUrl = 'http://central.maven.org/maven2/org/postgresql/postgresql/42.1.4/postgresql-42.1.4.jar'
$archiveHash = '4523ed32e9245e762e1df9f0942a147bece06561770a9195db093d9802297735'
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
