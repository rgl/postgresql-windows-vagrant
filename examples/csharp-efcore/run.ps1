# restore the packages.
dotnet restore

# show the ef-core tools version.
dotnet ef --version

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics ef database update --configuration Release --no-build
dotnet --diagnostics run --configuration Release --no-build
