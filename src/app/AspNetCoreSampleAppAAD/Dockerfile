FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build-env
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
WORKDIR /app
COPY --from=build-env /app/out .

# ... and run as non-root user.
RUN chown -R www-data:www-data /app

# TODO: Follow up here, this is a bug in the ASP.NET Core Identity Module.
RUN mkdir -p /var/www/ASP.NET/
RUN chown -R www-data:www-data /var/www/ASP.NET/ 
USER www-data

ENV ASPNETCORE_URLS http://+:8080
ENTRYPOINT ["dotnet", "AspNetCoreSampleAppAAD.dll"]
