# see https://community.chocolatey.org/packages/chocolatey
# renovate: datasource=nuget:chocolatey depName=chocolatey
$env:chocolateyVersion = '2.2.2'

Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
