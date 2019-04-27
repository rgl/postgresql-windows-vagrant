if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://dotnet.microsoft.com/download/dotnet-core/2.1
    # see https://github.com/dotnet/core/blob/master/release-notes/2.1/2.1.603-SDK/2.1.603-SDK-download.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/78863fe4-e032-433d-bbc3-f62d6df616ec/b075f5b4bc001b14465e27fdb1c21f07/dotnet-sdk-2.1.603-win-x64.exe'
    $archiveHash = '0294efe28b0216f13973cea909967745d36fe606bf2a0cbb100787e91cb8d92cab8aa2fdc020226f51ff39dc943ab74724183debae9b14afda2f04f07a7e8e3f'
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
