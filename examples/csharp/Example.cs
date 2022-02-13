using System;
using Npgsql;

class Example
{
    static void Main(string[] args)
    {
        // see http://www.npgsql.org/doc/connection-string-parameters.html
        // see http://www.npgsql.org/doc/security.html
        // NB npgsql uses the native windows Trusted Root Certification Authorities store to validate the server certificate.
        var connectionString = "Host=postgresql.example.com; Port=5432; SSL Mode=Disable; Username=postgres; Password=postgres; Database=postgres";
        var connectionStringSsl = connectionString.Replace("SSL Mode=Disable", "SSL Mode=VerifyFull");

        Console.WriteLine("PostgreSQL Version:");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select version()"));

        Console.WriteLine("PostgreSQL Version:");
        Console.WriteLine(SqlExecuteScalar(connectionString, "show server_version"));

        Console.WriteLine("PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select current_user"));

        Console.WriteLine("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"));

        Console.WriteLine("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; encrypted TCP/IP connection):");
        Console.WriteLine(SqlExecuteScalar(connectionStringSsl, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"));
    }

    private static object SqlExecuteScalar(string connectionString, string sql)
    {
        using (var connection = new NpgsqlConnection(connectionString))
        {
            connection.Open();

            using (var command = connection.CreateCommand())
            {
                command.CommandText = sql;
                return command.ExecuteScalar();
            }
        }
    }
}
