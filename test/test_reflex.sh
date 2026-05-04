#!/bin/bash
echo "🔍 Starting Project Sentinel Smoke Test..."

set -a
. ./.env
set +a

BRAIN_HOST_PORT="${BRAIN_HOST_PORT:-18000}"
INGESTION_HOST_PORT="${INGESTION_HOST_PORT:-18001}"
STATUS_API_HOST_PORT="${STATUS_API_HOST_PORT:-18002}"

# 1. Check Container Health
RUNNING=$(podman ps --format '{{.Names}}' | grep sentinel | wc -l)
echo "✅ Containers Running: $RUNNING/7"

# 2. Check Ingestion API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${INGESTION_HOST_PORT}/status")
if [ $STATUS -eq 200 ]; then
    echo "✅ Ingestion API: Operational"
else
    echo "❌ Ingestion API: Failed (Code $STATUS)"
fi

# 3. Check Prometheus Metrics Bridge (status-api)
METRICS=$(curl -s "http://localhost:${STATUS_API_HOST_PORT}/metrics" | grep sentinel_cpu_load)
if [[ ! -z "$METRICS" ]]; then
    echo "✅ Metrics Bridge: Sending Data"
else
    echo "❌ Metrics Bridge: No Data Found"
fi

echo "🚀 Smoke Test Complete."