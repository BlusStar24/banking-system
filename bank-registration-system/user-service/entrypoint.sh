#!/bin/sh
echo "Waiting for MySQL to be ready..."
timeout=30
while ! mysqladmin ping -h mysql --silent; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "Timeout waiting for MySQL"
        exit 1
    fi
done
echo "MySQL is ready, starting application..."
dotnet user-service.dll