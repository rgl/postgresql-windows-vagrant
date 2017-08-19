// see https://github.com/pgjdbc/pgjdbc
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class Example {
    public static void main(String[] args) throws Exception {
        String connectionString = "jdbc:postgresql://localhost:5432/postgres?user=postgres&password=postgres";

        System.out.println("PostgreSQL Version:");
        System.out.println(queryScalar(connectionString, "select version()"));

        System.out.println("PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        System.out.println(queryScalar(connectionString, "select current_user"));

        System.out.println("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        System.out.println(queryScalar(connectionString, "select ssl from pg_stat_ssl where pid=pg_backend_pid()"));
    }

    private static String queryScalar(String connectionString, String sql) throws Exception {
        try (Connection connection = DriverManager.getConnection(connectionString)) {
            try (Statement statement = connection.createStatement()) {
                try (ResultSet resultSet = statement.executeQuery(sql)) {
                    if (resultSet.next()) {
                        return resultSet.getString(1);
                    }
                    return null;
                }
            }
        }
    }
}
