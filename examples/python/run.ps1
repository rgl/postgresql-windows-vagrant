# install python.
# see https://community.chocolatey.org/packages/python
# renovate: datasource=nuget:chocolatey depName=python
$pythonVersion = '3.12.2'
choco install -y python --version $pythonVersion

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt

# run the example.
python main.py
