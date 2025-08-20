FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish message-service.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# ✅ Ensure appsettings.json được copy vào đúng thư mục /app
# Nếu đã có trong publish thì không cần dòng dưới
# COPY appsettings.json .

CMD ["dotnet", "message-service.dll"]
