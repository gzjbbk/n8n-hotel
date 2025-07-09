#\!/bin/bash

# Script untuk scaling n8n workers
# Usage: ./scaling.sh [up < /dev/null | down] [number]

ACTION=$1
NUMBER=$2

if [[ "$ACTION" == "up" ]]; then
    echo "Scaling up n8n workers to $NUMBER instances..."
    docker-compose up -d --scale n8n-worker=$NUMBER
elif [[ "$ACTION" == "down" ]]; then
    echo "Scaling down n8n workers to $NUMBER instances..."
    docker-compose up -d --scale n8n-worker=$NUMBER
elif [[ "$ACTION" == "status" ]]; then
    echo "Current service status:"
    docker-compose ps
    echo ""
    echo "Worker logs:"
    docker-compose logs n8n-worker
else
    echo "Usage: $0 [up|down|status] [number]"
    echo "Example: $0 up 3"
    echo "Example: $0 down 1"
    echo "Example: $0 status"
fi
