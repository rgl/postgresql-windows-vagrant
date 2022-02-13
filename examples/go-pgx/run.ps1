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
.\gopgx.exe
