import asyncio
import asyncpg
import os

# see https://magicstack.github.io/asyncpg/current/
# see https://www.postgresql.org/docs/11/libpq-connect.html#LIBPQ-CONNECT-SSLMODE
# NB asyncpg uses %PGSSLROOTCERT% or %USERPROFILE%\.postgresql\root.crt file to validate the server certificate.
async def sql_execute_scalar(sql, ssl='disable'):
    # TODO use async with connect when https://github.com/MagicStack/asyncpg/issues/760 is implemented.
    connection = await asyncpg.connect(
        host='postgresql.example.com',
        port=5432,
        ssl=ssl,
        user='postgres',
        password='postgres',
        database='postgres')
    try:
        return await connection.fetchval(sql)
    finally:
        await connection.close()

async def main():
    # setup asyncpg to load trusted certificates from %APPDATA%\postgresql\root.crt (which was already setup for use by psycopg2 example).
    if not os.getenv('PGSSLROOTCERT'):
        os.environ['PGSSLROOTCERT'] = os.getenv('APPDATA') + '\\postgresql\\root.crt'

    print('PostgreSQL Version:')
    print(await sql_execute_scalar('select version()'))

    print('PostgreSQL Version:')
    print(await sql_execute_scalar('show server_version'))

    print('PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):')
    print(await sql_execute_scalar('select current_user'))

    print('Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):')
    print(await sql_execute_scalar("select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"))

    print('Is this PostgreSQL connection encrypted? (postgres; username/password credentials; encrypted TCP/IP connection):')
    print(await sql_execute_scalar("select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()", ssl='verify-full'))

asyncio.run(main())
