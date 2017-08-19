using System;
using Npgsql;

class Example
{
    static void Main(string[] args)
    {
        // see http://www.npgsql.org/doc/connection-string-parameters.html
        var connectionString = "Host=localhost; Port=5432; Username=postgres; Password=postgres; Database=postgres";

        Console.WriteLine("PostgreSQL Version:");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select version()"));

        Console.WriteLine("PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select current_user"));

        Console.WriteLine("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):");
        Console.WriteLine(SqlExecuteScalar(connectionString, "select ssl from pg_stat_ssl where pid=pg_backend_pid()"));
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
