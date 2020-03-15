javac `
    -Werror `
    -d build/classes `
    -cp 'C:/Program Files/DBeaver/plugins/*' `
    src/com/ruilopes/*.java
jar cfm build/dbeaver-config.jar src/META-INF/MANIFEST.MF -C build/classes .
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
