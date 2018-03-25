import psycopg2

# see http://initd.org/psycopg/docs/
# see https://www.postgresql.org/docs/10/static/libpq-connect.html#LIBPQ-CONNECT-SSLMODE
# NB psycopg2 uses the %APPDATA%\postgresql\root.crt file to validate the server certificate.
def sql_execute_scalar(data_source_name, sql):
    with psycopg2.connect(data_source_name) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchone()[0]

data_source_name = 'host=postgresql.example.com port=5432 sslmode=disable user=postgres password=postgres dbname=postgres'
data_source_name_ssl = data_source_name.replace('sslmode=disable', 'sslmode=verify-full')

print('PostgreSQL Version:')
print(sql_execute_scalar(data_source_name, 'select version()'))

print('PostgreSQL Version:')
print(sql_execute_scalar(data_source_name, 'show server_version'))

print('PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):')
print(sql_execute_scalar(data_source_name, 'select current_user'))

print('Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):')
print(sql_execute_scalar(data_source_name, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"))

print('Is this PostgreSQL connection encrypted? (postgres; username/password credentials; encrypted TCP/IP connection):')
print(sql_execute_scalar(data_source_name_ssl, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"))
