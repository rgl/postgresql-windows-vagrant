# install go.
# see https://community.chocolatey.org/packages/golang
choco install -y golang --version 1.19.4

# setup the current process environment.
$env:GOROOT = 'C:\Program Files\Go'
$env:PATH += ";$env:GOROOT\bin"

# setup the Machine environment.
[Environment]::SetEnvironmentVariable('GOROOT', $env:GOROOT, 'Machine')
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:GOROOT\bin",
    'Machine')

Write-Host '# go env'
go env

Write-Host '# install dependencies'
go mod download

Write-Host '# build and run'
$p = Start-Process go 'build','-v' `
    -RedirectStandardOutput build-stdout.txt `
    -RedirectStandardError build-stderr.txt `
    -Wait `
    -PassThru
Write-Output (Get-Content build-stdout.txt,build-stderr.txt)
Remove-Item build-stdout.txt,build-stderr.txt
if ($p.ExitCode) {
    throw "Failed to compile"
}
.\gopg.exe
