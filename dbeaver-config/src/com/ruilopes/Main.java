package com.ruilopes;

import java.nio.file.Files;
import java.nio.file.Paths;

import org.jkiss.dbeaver.model.impl.app.DefaultSecureStorage;
import org.jkiss.dbeaver.runtime.encode.ContentEncrypter;

public class Main {
    public static void main(String[] args) throws Exception {
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/features/org.jkiss.dbeaver.ce.feature/root/readme.txt#L28
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.core.application/src/org/jkiss/dbeaver/core/application/DBeaverApplication.java#L76
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.registry/src/org/jkiss/dbeaver/registry/DataSourceSerializerModern.java#L293
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.registry/src/org/jkiss/dbeaver/registry/DataSourceSerializerModern.java#L267
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.model/src/org/jkiss/dbeaver/model/impl/app/DefaultSecureStorage.java#L30
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.model/src/org/jkiss/dbeaver/runtime/encode/ContentEncrypter.java#L37
        // see https://github.com/dbeaver/dbeaver/blob/release_7_0_0/plugins/org.jkiss.dbeaver.model/src/org/jkiss/dbeaver/runtime/encode/ContentEncrypter.java#L54
        ContentEncrypter contentEncrypter = new ContentEncrypter(DefaultSecureStorage.INSTANCE.getLocalSecretKey());

        switch (args[0]) {
            case "encrypt":
                {
                    String credentialsConfigJson = new String(Files.readAllBytes(Paths.get(args[1])), "UTF8");
                    byte[] contents = contentEncrypter.encrypt(credentialsConfigJson);
                    Files.write(Paths.get(args[2]), contents);
                }
                break;
            case "decrypt":
                {
                    byte[] contents = Files.readAllBytes(Paths.get(args[1]));
                    String credentialsConfigJson = contentEncrypter.decrypt(contents);
                    System.out.println(credentialsConfigJson);
                }
                break;
            default:
                throw new Exception("Unknown command");
        }

    }
}
