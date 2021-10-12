if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://dotnet.microsoft.com/download/dotnet-core/3.1
    # see https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1.19/3.1.19.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    # NB keep this in sync with provision-iis-dotnetcore-hosting.ps1
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/70062b11-491c-403c-91db-9d84462ee292/5db435e39128cbb608e76bf5111ab3dc/dotnet-sdk-3.1.413-win-x64.exe'
    $archiveHash = '878ca8654df81a363c4cddddb5303857f3e21be684f191f5c9cff1505038e4303524890edd778892ea13b752ea112d9ecdbb3ada2fdd8439071e6160ce02b8d7'
    $archiveName = Split-Path -Leaf $archiveUrl
    $archivePath = "$env:TEMP\$archiveName"
    Write-Host "Downloading $archiveName..."
    (New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA512).Hash
    if ($archiveHash -ne $archiveActualHash) {
        throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
    }
    Write-Host "Installing $archiveName..."
    &$archivePath /install /quiet /norestart | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
    }
    Remove-Item $archivePath

    # reload PATH.
    $env:PATH = "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$([Environment]::GetEnvironmentVariable('PATH', 'User'))"
}

# show information about dotnet.
dotnet --info

# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics run --configuration Release
