#!/bin/bash +xe

# Open port 8084 for testing network performance monitor
firewall-cmd --add-port=8084/tcp

server=$(find ./simple-healthcheck-server* -type f)

echo "Starting health check server: $server"
chmod +x $server
nohup ./$server | logger -t simple-healtcheck-server &
echo "Started health check server"
