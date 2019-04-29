Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

# install rust.
choco install -y visualstudio2019-workload-vctools
choco install -y rust-ms
Update-SessionEnvironment

Write-Host '# rust version'
rustc --version

Write-Host '# install dependencies'
cargo build --release

Write-Host '# dependencies'
$dumpBinPath = Resolve-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe'
&$dumpBinPath /dependents .\target\release\rust.exe

Write-Host '# run'
.\target\release\rust.exe
