# install the PostgreSQL JDBC driver.
@(
    ,@('http://central.maven.org/maven2/org/postgresql/postgresql/42.2.5/postgresql-42.2.5.jar', '7ffa46f8c619377cdebcd17721b6b21ecf6659850179f96fec3d1035cf5a0cdc')
    ,@('http://central.maven.org/maven2/net/postgis/postgis-jdbc/2.2.1/postgis-jdbc-2.2.1.jar', '8bb36080e752257b8547402090b5d05e54dd89fc0814bd299e14ccab8d31715c')
    ,@('http://central.maven.org/maven2/net/postgis/postgis-jdbc-jtsparser/2.2.1/postgis-jdbc-jtsparser-2.2.1.jar', '60ad4b9959ac54ac419b4db278004a98fb821209b889bba752f543bf90edd1fc')
) | ForEach-Object {
    $archiveUrl = $_[0]
    $archiveHash = $_[1]
    $archiveName = Split-Path -Leaf $archiveUrl
    $archivePath = "$env:USERPROFILE\.dbeaver-drivers\$archiveName"
    Write-Host "Downloading $archiveName..."
    mkdir -Force (Split-Path -Parent $archivePath) | Out-Null
    Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
    if ($archiveHash -ne $archiveActualHash) {
        throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
    }
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
