if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://dotnet.microsoft.com/download/dotnet-core/2.1
    # see https://github.com/dotnet/core/blob/master/release-notes/2.1/2.1.502-SDK/2.1.502.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/70b3a142-06fa-4d86-b1cc-67a48c1eaacb/55e147bd47db930a642a8f8176949a76/dotnet-sdk-2.1.502-win-x64.exe'
    $archiveHash = '20e5d2e54ccad8ce2c5eed0effcba5d610c8bf1d15f8d2ee2e792547b35697ea408a415d2f580e0e2f693339e5e10f0a46b82b88171016378afbba4bf4a55227'
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
