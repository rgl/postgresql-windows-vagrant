# create the database, roles and users.
$env:PGUSER = 'postgres'
$env:PGPASSWORD = 'postgres'
$serviceHome = 'C:/postgresql'
function psql {
    &"$serviceHome/bin/psql.exe" -v ON_ERROR_STOP=1 -w @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}
<#
psql -c 'drop database startrekefcore'
psql -c @'
drop role csharp_efcore_app;
drop role startrekefcore_owner;
drop role startrekefcore_writer;
drop role startrekefcore_reader;
'@
#>
psql -c 'create database startrekefcore' postgres
psql -c @'
--
-- roles.
--
create role startrekefcore_owner login password 'password';
create role startrekefcore_reader;
create role startrekefcore_writer;
--
-- permissions.
--
revoke all privileges on database startrekefcore from public;
grant all privileges on database startrekefcore to startrekefcore_owner;
grant connect on database startrekefcore to startrekefcore_writer;
grant connect on database startrekefcore to startrekefcore_reader;
--
-- csharp_efcore_app user.
--
create role csharp_efcore_app login password 'password';
grant startrekefcore_writer to csharp_efcore_app;
grant startrekefcore_reader to csharp_efcore_app;
'@ postgres
psql -c @'
--
-- startrekefcore_writer role.
--
grant usage on schema public to startrekefcore_writer;
alter default privileges for role startrekefcore_owner in schema public grant select, insert on tables to startrekefcore_writer;
alter default privileges for role startrekefcore_owner in schema public grant select, update on sequences to startrekefcore_writer;
alter default privileges for role startrekefcore_owner in schema public grant execute on functions to startrekefcore_writer;
--
-- startrekefcore_reader role.
--
grant usage on schema public to startrekefcore_reader;
alter default privileges for role startrekefcore_owner in schema public grant select on tables to startrekefcore_reader;
alter default privileges for role startrekefcore_owner in schema public grant select on sequences to startrekefcore_reader;
alter default privileges for role startrekefcore_owner in schema public grant execute on functions to startrekefcore_reader;
'@ startrekefcore
Remove-Item env:PGUSER
Remove-Item env:PGPASSWORD

# restore the packages.
dotnet restore

# show the ef-core tools version.
dotnet tool install --global dotnet-ef --version 6.0.8
dotnet ef --version

# build.
dotnet --diagnostics build --configuration Release

# update the database schema.
dotnet --diagnostics ef database update --configuration Release --no-build

# run.
dotnet --diagnostics run --configuration Release --no-build
