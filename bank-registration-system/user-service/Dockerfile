FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Sao chép và restore
COPY user-service.csproj .
RUN dotnet restore

# Sao chép mã nguồn và build
COPY . .
RUN dotnet build -c Release

# Cài đặt dotnet-ef
RUN dotnet tool install --global dotnet-ef --version 8.0.0
ENV PATH="$PATH:/root/.dotnet/tools"

# Publish
RUN dotnet publish -c Release -o out

# Runtime image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS runtime
WORKDIR /app

# Cài đặt mariadb-client để có mysqladmin
RUN apt-get update && apt-get install -y mariadb-client && apt-get clean

# Cài đặt lại dotnet-ef trong giai đoạn runtime
RUN dotnet tool install --global dotnet-ef --version 8.0.0
ENV PATH="$PATH:/root/.dotnet/tools"

# Sao chép file .csproj và thư mục Migrations
COPY user-service.csproj .
COPY Migrations ./Migrations
COPY appsettings.json .

COPY --from=build /app/out .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]