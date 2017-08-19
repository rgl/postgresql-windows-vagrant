import psycopg2

# see http://initd.org/psycopg/docs/
def sql_execute_scalar(data_source_name, sql):
    with psycopg2.connect(data_source_name) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchone()[0]

data_source_name = 'host=localhost port=5432 user=postgres password=postgres dbname=postgres sslmode=disable'

print('PostgreSQL Version:')
print(sql_execute_scalar(data_source_name, 'select version()'))

print('PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):')
print(sql_execute_scalar(data_source_name, 'select current_user'))

print('Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):')
print(sql_execute_scalar(data_source_name, 'select ssl from pg_stat_ssl where pid=pg_backend_pid()'))
