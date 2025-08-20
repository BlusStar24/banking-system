# ================================================
# 1. Base image chạy ASP.NET runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# ================================================
# 2. SDK image để build .NET
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["transfer-service.csproj", "./"]
RUN dotnet restore "transfer-service.csproj"
COPY . .
RUN dotnet build "transfer-service.csproj" -c Release -o /app/build

# ================================================
# 3. Publish ASP.NET app
FROM build AS publish
RUN dotnet publish "transfer-service.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ================================================
# 4. Final image: ASP.NET runtime + Node.js
FROM base AS final

# Đặt biến môi trường Bonita nếu cần dùng
ENV BONITA_BASE_URL=http://host.docker.internal:25854/bonita

# Cài Node.js + PM2
RUN apt-get update && apt-get install -y curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pm2

# Copy Node.js app
COPY ./workflow-api/ /app/workflow-api/
WORKDIR /app/workflow-api
RUN npm install
RUN npm install pm2 axios mysql2

# Copy ASP.NET app đã publish
WORKDIR /app
COPY --from=publish /app/publish .

# Copy file cấu hình PM2
COPY ./ecosystem.config.js .

# ================================================
# 5. Chạy ASP.NET Core + Node.js song song bằng PM2
CMD ["pm2-runtime", "ecosystem.config.js"]
