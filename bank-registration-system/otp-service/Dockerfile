FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5001

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy toàn bộ thư mục otp-service (đã là context gốc)
COPY . .

# Vì otp-service.csproj nằm ở /src
RUN dotnet restore otp-service.csproj

# Build project này
RUN dotnet publish otp-service.csproj -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "otp-service.dll"]
