This is a [PostgreSQL](https://www.postgresql.org/) on Windows Server 2022 Vagrant environment playground.

# Usage

Install the [Base Windows 2022 Box](https://github.com/rgl/windows-vagrant).

Then launch the environment:

```bash
vagrant up
```

The default superuser username and password are `postgres`.

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
```

# SSL

Different libraries use different sources to validate the server certificate:

| App/Library     | Default trust store location                            |
| --------------- | ------------------------------------------------------- |
| pgAdmin         | `%APPDATA%/postgresql/root.crt` file                    |
| Python psycopg2 | `%APPDATA%/postgresql/root.crt` file                    |
| Java postgresql | `%APPDATA%/postgresql/root.crt` file                    |
| .NET Npgsql     | Windows `Trusted Root Certification Authorities` store  |
| Go lib/pq       | Windows `Trusted Root Certification Authorities` store  |
