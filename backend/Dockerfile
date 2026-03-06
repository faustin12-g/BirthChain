# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files first (for better caching)
COPY BirthChain.sln .
COPY nuget.config .
COPY src/BirthChain.Core/BirthChain.Core.csproj src/BirthChain.Core/
COPY src/BirthChain.Application/BirthChain.Application.csproj src/BirthChain.Application/
COPY src/BirthChain.Infrastructure/BirthChain.Infrastructure.csproj src/BirthChain.Infrastructure/
COPY src/BirthChain.API/BirthChain.API.csproj src/BirthChain.API/

# Restore dependencies
RUN dotnet restore BirthChain.sln

# Copy everything else and build
COPY . .
RUN dotnet publish src/BirthChain.API/BirthChain.API.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Copy published files
COPY --from=build /app/publish .

# Expose dynamic port (Railway uses PORT env variable)
EXPOSE 8080

# Set environment to Production
ENV ASPNETCORE_ENVIRONMENT=Production

# Entry point
ENTRYPOINT ["dotnet", "BirthChain.API.dll"]
