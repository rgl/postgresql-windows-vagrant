mkdir -Force $env:TEMP\dbeaver-config | Out-Null
cd $env:TEMP\dbeaver-config
javac `
    -Werror `
    -d build/classes `
    -cp 'C:/Program Files/DBeaver/plugins/*' `
    "$PSScriptRoot/src/com/ruilopes/*.java"
jar cfm build/dbeaver-config.jar "$PSScriptRoot/src/META-INF/MANIFEST.MF" -C build/classes .
# java `
#     -cp 'C:/Program Files/DBeaver/plugins/*;build/dbeaver-config.jar' `
#     com.ruilopes.Main `
#     decrypt `
#     "$env:APPDATA/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"
java `
    -cp 'C:/Program Files/DBeaver/plugins/*;build/dbeaver-config.jar' `
    com.ruilopes.Main `
    encrypt `
    "C:/vagrant/provision-dbeaver-credentials-config.json" `
    "$env:APPDATA/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"
