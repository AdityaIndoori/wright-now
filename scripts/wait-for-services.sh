#!/bin/bash
# Wait for Services Script
# Waits for all infrastructure services to be healthy before proceeding
# Useful for CI/CD pipelines and ensuring services are ready

set -e

echo "⏳ Waiting for WRight Now services to be ready..."

# Configuration
MAX_WAIT_SECONDS=120
CHECK_INTERVAL=5
ELAPSED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a service is healthy
check_service() {
    local service_name=$1
    local check_command=$2
    
    echo -n "Checking $service_name... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ready${NC}"
        return 0
    else
        echo -e "${YELLOW}⏳ Waiting${NC}"
        return 1
    fi
}

# Function to wait for a service with timeout
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local waited=0
    
    while [ $waited -lt $MAX_WAIT_SECONDS ]; do
        if check_service "$service_name" "$check_command"; then
            return 0
        fi
        
        sleep $CHECK_INTERVAL
        waited=$((waited + CHECK_INTERVAL))
    done
    
    echo -e "${RED}✗ Timeout waiting for $service_name${NC}"
    return 1
}

# Check PostgreSQL
echo ""
echo "=== PostgreSQL ==="
if ! wait_for_service "PostgreSQL" "docker exec wrightnow-postgres pg_isready -U postgres"; then
    echo -e "${RED}Failed to connect to PostgreSQL${NC}"
    exit 1
fi

# Verify pg_vector extension
echo -n "Verifying pg_vector extension... "
if docker exec wrightnow-postgres psql -U postgres -d wrightnow -tAc "SELECT 1 FROM pg_extension WHERE extname='vector'" | grep -q 1; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    exit 1
fi

# Check Redis
echo ""
echo "=== Redis ==="
if ! wait_for_service "Redis" "docker exec wrightnow-redis redis-cli ping | grep -q PONG"; then
    echo -e "${RED}Failed to connect to Redis${NC}"
    exit 1
fi

# Check Authentik PostgreSQL
echo ""
echo "=== Authentik PostgreSQL ==="
if ! wait_for_service "Authentik PostgreSQL" "docker exec wrightnow-authentik-postgres pg_isready -U authentik"; then
    echo -e "${RED}Failed to connect to Authentik PostgreSQL${NC}"
    exit 1
fi

# Check Authentik Redis
echo ""
echo "=== Authentik Redis ==="
if ! wait_for_service "Authentik Redis" "docker exec wrightnow-authentik-redis redis-cli ping | grep -q PONG"; then
    echo -e "${RED}Failed to connect to Authentik Redis${NC}"
    exit 1
fi

# Check Authentik Server
echo ""
echo "=== Authentik Server ==="
if ! wait_for_service "Authentik Server" "curl -sf http://localhost:9000/api/v3/root/config/"; then
    echo -e "${RED}Failed to connect to Authentik Server${NC}"
    exit 1
fi

# Summary
echo ""
echo "============================================"
echo -e "${GREEN}✓ All services are ready!${NC}"
echo "============================================"
echo ""
echo "Service URLs:"
echo "  PostgreSQL:  localhost:5432 (user: postgres, db: wrightnow)"
echo "  Redis:       localhost:6379"
echo "  Authentik:   http://localhost:9000"
echo ""
echo "Next steps:"
echo "  1. Access Authentik at http://localhost:9000 to complete initial setup"
echo "  2. Run tests: npm test (or your test command)"
echo "  3. View logs: docker-compose logs -f"
echo ""

exit 0
