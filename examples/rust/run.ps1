Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

# install rust.
# see https://community.chocolatey.org/packages/rust-ms
choco install -y visualstudio2019-workload-vctools
choco install -y rust-ms --version 1.58.1
Update-SessionEnvironment

Write-Host '# rust version'
rustc --version

Write-Host '# build'
# rust cannot sucessfully compile in a shared directory (like c:\vagrant),
# so we have to point it to a local directory with the CARGO_TARGET_DIR
# environment variable. 
# see https://github.com/rust-lang/rust/issues/54216#issuecomment-448282142
$env:CARGO_TARGET_DIR = 'C:\tmp\rust-target'
cargo build --release

Write-Host '# dependencies'
$dumpBinPath = Resolve-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe'
&$dumpBinPath /dependents "$env:CARGO_TARGET_DIR\release\rust.exe"

Write-Host '# run'
&"$env:CARGO_TARGET_DIR\release\rust.exe"
