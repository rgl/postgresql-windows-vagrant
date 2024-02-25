# install.
# see https://community.chocolatey.org/packages/pgadmin4
# renovate: datasource=nuget:chocolatey depName=pgadmin4
$pgadmin4Version = '8.0.0'
choco install -y pgadmin4 --version $pgadmin4Version
