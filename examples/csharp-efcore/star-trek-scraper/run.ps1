Write-Host 'Installing dependencies...'
choco install -y nodejs-lts --version 14.18.0

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# copy everything to disk because running puppeter from the vagrant network share does not work.
mkdir -Force $env:TEMP\star-trek-scraper | Out-Null
Copy-Item * $env:TEMP\star-trek-scraper
Push-Location $env:TEMP\star-trek-scraper

npm install

Write-Host 'Running...'
# NB to troubleshoot uncomment $env:DEBUG and set {headless:false,dumpio:true} in main.js.
#$env:DEBUG = 'puppeteer:*'
node main.js

# copy the results back to the network share.
Copy-Item data.json $PSScriptRoot

Pop-Location
