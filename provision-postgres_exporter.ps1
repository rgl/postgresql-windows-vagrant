# install go.
choco install -y golang
$env:GOROOT = 'C:\tools\go'
$env:PATH += ";$env:GOROOT\bin"

# converts/escapes a string to a command line argument.
function ConvertTo-CommandLineArgument {
    # Normally, an Windows application (.NET applications too) parses
    # their command line using the CommandLineToArgvW function. Which has
    # some peculiar rules.
    # See http://msdn.microsoft.com/en-us/library/bb776391(VS.85).aspx
    #
    # TODO how about backslashes? there seems to be a weird interaction
    #      between backslahses and double quotes...
    process {
        if ($_.Contains('"')) {
            # escape single double quotes with another double quote.
            return '"{0}"' -f $_.Replace('"', '""')
        } elseif ($_.Contains(' ')) { # AND it does NOT contain double quotes! (those were catched in the previous test)
            return '"{0}"' -f $_
        } elseif ($_ -eq '') {
            return '""'
        } else {
            return $_
        }
    }
}
function Start-WrappedProcess([string]$ProcessPath, [string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    $p = Start-Process $ProcessPath ($Arguments | ConvertTo-CommandLineArgument) `
        -RedirectStandardOutput $env:TEMP\stdout.txt `
        -RedirectStandardError $env:TEMP\stderr.txt `
        -WindowStyle Hidden `
        -Wait `
        -PassThru
    Write-Output (Get-Content $env:TEMP\stdout.txt,$env:TEMP\stderr.txt)
    Remove-Item $env:TEMP\stdout.txt,$env:TEMP\stderr.txt
    if ($SuccessExitCodes -NotContains $p.ExitCode) {
        throw "$(@($ProcessPath)+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
    }
}
function git {
    Start-WrappedProcess git $Args
}
function go {
    Start-WrappedProcess go $Args
}

# build postgres_exporter from source code.
# see https://github.com/wrouesnel/postgres_exporter/blob/master/Makefile
Push-Location $env:TEMP
mkdir postgres_exporter/src | Out-Null
cd postgres_exporter
$env:GOPATH = $PWD.Path
cd src
git clone -b master https://github.com/rgl/postgres_exporter.git
cd postgres_exporter
go build -v -ldflags "-extldflags -static -X main.Version=$(git describe --dirty)"
del env:GOPATH
Pop-Location

$serviceHome = 'C:/postgres_exporter'
$serviceName = 'postgres_exporter'
$serviceUsername = "NT SERVICE\$serviceName"

# install the binary.
mkdir $serviceHome | Out-Null
Copy-Item "$env:TEMP/postgres_exporter/src/postgres_exporter/postgres_exporter.exe" $serviceHome

# install the service.
choco install -y nssm
nssm install $serviceName "$serviceHome/postgres_exporter.exe"

# setup the service account.
$result = sc.exe sidtype $serviceName unrestricted
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe sidtype failed with $result"
}

# create and protect the logs sub-directory.
mkdir $serviceHome/logs | Out-Null
Disable-AclInheritance $serviceHome/logs
Grant-Permission $serviceHome/logs SYSTEM FullControl
Grant-Permission $serviceHome/logs Administrators FullControl
Grant-Permission $serviceHome/logs $serviceUsername FullControl

# protect the registry key that will contain secret environment variables.
$serviceParametersKey = "HKLM:\System\CurrentControlSet\Services\$serviceName\Parameters"
$serviceParametersKeyAcl = New-Object System.Security.AccessControl.RegistrySecurity
$serviceParametersKeyAcl.SetAccessRuleProtection($true, $false)
@(
    'SYSTEM'
    'Administrators'
) | ForEach-Object {
    $serviceParametersKeyAcl.AddAccessRule((
        New-Object `
            System.Security.AccessControl.RegistryAccessRule(
                $_,
                'FullControl',
                'ContainerInherit,ObjectInherit',
                'None',
                'Allow')))
}
$serviceParametersKeyAcl.AddAccessRule((
    New-Object `
        System.Security.AccessControl.RegistryAccessRule(
                $serviceUsername,
                'ReadKey',
                'ContainerInherit,ObjectInherit',
                'None',
                'Allow')))
Set-Acl $serviceParametersKey $serviceParametersKeyAcl

# configure the service.
nssm set $serviceName Start SERVICE_AUTO_START
nssm set $serviceName AppRotateFiles 1
nssm set $serviceName AppRotateOnline 1
nssm set $serviceName AppRotateSeconds 86400
nssm set $serviceName AppRotateBytes 1048576
nssm set $serviceName AppStdout $serviceHome\logs\service.log
nssm set $serviceName AppStderr $serviceHome\logs\service.log
nssm set $serviceName AppParameters `
    '-web.listen-address=localhost:9187'
nssm set $serviceName AppEnvironmentExtra `
    'DATA_SOURCE_NAME=postgres://postgres:postgres@localhost?sslmode=disable'

# configure the service account.
$result = sc.exe config $serviceName obj= $serviceUsername
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}
$result = sc.exe failure $serviceName reset= 0 actions= restart/1000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure failed with $result"
}

# start the service.
Start-Service $serviceName

# give it a try.
(Invoke-RestMethod 'http://localhost:9187/metrics') -split '\r?\n' | Where-Object {$_ -match 'pg_exporter_'}
