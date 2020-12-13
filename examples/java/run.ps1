# install dependencies.
choco install -y adoptopenjdk11
choco install -y gradle --version 6.7.1

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# build into a fat jar.
# NB gradle build would also work, but having a fat jar is nicier for distribution.
Write-Output 'Building the example...'
$env:GRADLE_OPTS = '-Dorg.gradle.daemon=false' # to save memory, do not leave the daemon running in background.
gradle clean shadowJar --warning-mode all

# run the example.
Write-Output 'Executing the example...'
java -jar build/libs/example-1.0.0-all.jar
