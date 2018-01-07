# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics ef database update --configuration Release --no-build
dotnet --diagnostics run --configuration Release --no-build
