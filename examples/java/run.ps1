# install dependencies.
choco install -y jdk8 gradle

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# build into a fat jar.
# NB gradle build would also work, but having a fat jar is nicier for distribution.
gradle shadowJar

# run the example.
java -jar build/libs/example-1.0.0-all.jar