#!/bin/bash
echo "🔍 Starting Project Sentinel Smoke Test..."

# 1. Check Container Health
RUNNING=$(docker ps --format '{{.Names}}' | grep sentinel | wc -l)
echo "✅ Containers Running: $RUNNING/7"

# 2. Check Ingestion API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/status)
if [ $STATUS -eq 200 ]; then
    echo "✅ Ingestion API: Operational"
else
    echo "❌ Ingestion API: Failed (Code $STATUS)"
fi

# 3. Check Prometheus Metrics Bridge (status-api on port 8002)
METRICS=$(curl -s http://localhost:8002/metrics | grep sentinel_cpu_load)
if [[ ! -z "$METRICS" ]]; then
    echo "✅ Metrics Bridge: Sending Data"
else
    echo "❌ Metrics Bridge: No Data Found"
fi

echo "🚀 Smoke Test Complete."