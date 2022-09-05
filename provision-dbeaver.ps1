# install DBeaver.
# see https://community.chocolatey.org/packages/dbeaver
choco install -y dbeaver --version 21.3.5

# configure DBeaver.
$configPath = "$env:APPDATA\DBeaverData\workspace6\General\.dbeaver"
mkdir -Force $configPath | Out-Null
Copy-Item provision-dbeaver-data-sources.json "$configPath\data-sources.json"
Push-Location C:\vagrant\dbeaver-config
.\run.ps1
Pop-Location
