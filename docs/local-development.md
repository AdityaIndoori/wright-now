# Local Development Guide

This guide will help you set up and run the WRight Now development environment on your local machine.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Service Details](#service-details)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

- **Docker Desktop** (version 20.10 or higher)
  - [Download for Windows](https://www.docker.com/products/docker-desktop/)
  - [Download for macOS](https://www.docker.com/products/docker-desktop/)
  - [Download for Linux](https://docs.docker.com/engine/install/)

- **Docker Compose** (version 2.0 or higher)
  - Included with Docker Desktop on Windows/macOS
  - Linux: `sudo apt-get install docker-compose-plugin`

- **Git** (for version control)
  - [Download](https://git-scm.com/downloads)

### System Requirements

- **RAM:** 8GB minimum (16GB recommended)
- **Disk Space:** 10GB free space
- **OS:** Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)

### Verify Installation

```bash
# Check Docker version
docker --version
# Should output: Docker version 20.10.x or higher

# Check Docker Compose version
docker-compose --version
# Should output: Docker Compose version 2.x.x or higher

# Verify Docker is running
docker ps
# Should show no errors (may show empty list of containers)
```

## Quick Start

Follow these steps to get your development environment running in under 10 minutes:

### 1. Clone the Repository

```bash
git clone https://github.com/AdityaIndoori/wright-now.git
cd wright-now
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# (Optional) Edit .env if you need to customize settings
# The defaults work fine for most development scenarios
```

### 3. Start the Services

```bash
# Start all services in detached mode
docker-compose up -d

# This will:
# - Pull required Docker images (first time only, ~5 minutes)
# - Create Docker volumes for data persistence
# - Start PostgreSQL, Redis, and Authentik services
# - Run database initialization scripts
```

### 4. Wait for Services to Be Ready

```bash
# Run the wait script to ensure all services are healthy
./scripts/wait-for-services.sh

# Expected output:
# ✓ PostgreSQL Ready
# ✓ Redis Ready
# ✓ Authentik Server Ready
# ✓ All services are ready!
```

**Windows users:** If the script doesn't run, use Git Bash or WSL:
```bash
# Git Bash
bash ./scripts/wait-for-services.sh

# Or check manually
docker-compose ps
```

### 5. Verify Installation

```bash
# Check service health
docker-compose ps

# Expected output: All services should show "healthy" status
```

### 6. Complete Authentik Initial Setup

1. Open your browser and navigate to: http://localhost:9000
2. Follow the initial setup wizard to create an admin account
3. Recommended settings:
   - Admin email: `admin@localhost`
   - Admin password: Choose a secure password (saved in your password manager)

🎉 **You're all set!** Your development environment is now ready.

## Service Details

### PostgreSQL (Main Database)

- **Host:** `localhost`
- **Port:** `5432`
- **Database:** `wrightnow`
- **User:** `postgres`
- **Password:** `password` (see `.env` file)

**Connect via CLI:**
```bash
docker exec -it wrightnow-postgres psql -U postgres -d wrightnow
```

**Connect via GUI Tool:**
- Host: `localhost`
- Port: `5432`
- Database: `wrightnow`
- Username: `postgres`
- Password: `password`

**Verify pg_vector Extension:**
```sql
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
```

### Redis (Cache)

- **Host:** `localhost`
- **Port:** `6379`
- **Password:** None (development only)

**Connect via CLI:**
```bash
docker exec -it wrightnow-redis redis-cli
```

**Test Redis:**
```bash
docker exec -it wrightnow-redis redis-cli ping
# Expected output: PONG
```

### Authentik (OIDC Identity Provider)

- **Web UI:** http://localhost:9000
- **API:** http://localhost:9000/api/v3/
- **OIDC Discovery:** http://localhost:9000/application/o/.well-known/openid-configuration

**Access Admin Panel:**
1. Navigate to http://localhost:9000
2. Log in with your admin credentials
3. Configure OIDC applications for your services

## Common Tasks

### Viewing Logs

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f authentik-server

# View last 50 lines
docker-compose logs --tail=50 postgres
```

### Restarting Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart postgres
docker-compose restart redis
docker-compose restart authentik-server
```

### Stopping Services

```bash
# Stop all services (keeps volumes and data)
docker-compose stop

# Or stop and remove containers (keeps volumes and data)
docker-compose down

# Remove containers and volumes (⚠️ DELETES ALL DATA)
docker-compose down -v
```

### Resetting the Environment

**Warning:** This will delete all data including databases, configurations, and uploaded files.

```bash
# Stop and remove everything
docker-compose down -v

# Start fresh
docker-compose up -d

# Wait for services
./scripts/wait-for-services.sh
```

### Accessing Container Shells

```bash
# PostgreSQL container
docker exec -it wrightnow-postgres bash

# Redis container
docker exec -it wrightnow-redis sh

# Authentik server container
docker exec -it wrightnow-authentik-server bash
```

### Running Database Migrations

```bash
# Run migrations (when you add the Core Backend service)
docker exec -it wrightnow-core-backend npm run migrate

# Or if using Prisma
docker exec -it wrightnow-core-backend npx prisma migrate dev
```

### Backing Up Data

```bash
# Backup PostgreSQL database
docker exec wrightnow-postgres pg_dump -U postgres wrightnow > backup.sql

# Restore PostgreSQL database
cat backup.sql | docker exec -i wrightnow-postgres psql -U postgres wrightnow

# Backup Redis data
docker exec wrightnow-redis redis-cli --rdb /data/dump.rdb
```

## Troubleshooting

### Services Won't Start

**Problem:** `docker-compose up -d` fails or containers keep restarting

**Solution:**
```bash
# Check Docker is running
docker ps

# Check logs for errors
docker-compose logs

# Try rebuilding
docker-compose down -v
docker-compose up -d --force-recreate
```

### Port Already in Use

**Problem:** Error: `bind: address already in use`

**Solution:**
```bash
# Check what's using the port (example for port 5432)
# Windows
netstat -ano | findstr :5432

# macOS/Linux
lsof -i :5432

# Kill the process or change the port in docker-compose.yml
```

### Out of Disk Space

**Problem:** Docker runs out of disk space

**Solution:**
```bash
# Remove unused Docker resources
docker system prune -a --volumes

# Check disk usage
docker system df
```

### pg_vector Extension Not Found

**Problem:** Database queries fail with "extension vector does not exist"

**Solution:**
```bash
# Verify extension is installed
docker exec -it wrightnow-postgres psql -U postgres -d wrightnow -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"

# If not installed, run the init script manually
docker exec -it wrightnow-postgres bash /docker-entrypoint-initdb.d/init-db.sh

# Or recreate the database
docker-compose down -v
docker-compose up -d
```

### Authentik Not Accessible

**Problem:** http://localhost:9000 shows "Connection refused" or "502 Bad Gateway"

**Solution:**
```bash
# Check if Authentik server is healthy
docker-compose ps authentik-server

# Check logs
docker-compose logs authentik-server

# Wait longer (Authentik takes ~60 seconds to start)
./scripts/wait-for-services.sh

# Restart Authentik
docker-compose restart authentik-server
```

### Redis Connection Refused

**Problem:** Applications can't connect to Redis

**Solution:**
```bash
# Verify Redis is running
docker exec -it wrightnow-redis redis-cli ping

# Check Redis logs
docker-compose logs redis

# Restart Redis
docker-compose restart redis
```

### Slow Startup on Windows/macOS

**Problem:** `docker-compose up -d` is very slow

**Solution:**
- This is normal on first startup (downloading images)
- Subsequent startups should be faster
- Ensure Docker Desktop has enough resources allocated:
  - Docker Desktop → Settings → Resources
  - Recommended: 4 CPU cores, 8GB RAM

### Permission Errors (Linux)

**Problem:** Permission denied when accessing volumes

**Solution:**
```bash
# Fix permissions for scripts
chmod +x scripts/*.sh

# Or run with sudo (not recommended)
sudo docker-compose up -d
```

## CI/CD Integration

The Docker Compose setup integrates seamlessly with GitHub Actions for automated testing.

### Example GitHub Actions Workflow

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start infrastructure
        run: docker-compose up -d
      
      - name: Wait for services
        run: ./scripts/wait-for-services.sh
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Cleanup
        if: always()
        run: docker-compose down -v
```

### Key Points for CI/CD

1. **Use `wait-for-services.sh`** to ensure services are ready
2. **Always cleanup** with `docker-compose down -v` in the `finally` block
3. **Run tests in parallel** by using unique ports for each workflow
4. **Cache Docker layers** to speed up CI runs

## Next Steps

Now that your development environment is running:

1. **Read the main README.md** for project overview
2. **Review the Technical Design Doc** (`ProjectDocs/TechnicalDesignDoc.md`)
3. **Start Sprint 0 remaining tasks** (service scaffolding)
4. **Run the test suite** (when implemented)
5. **Begin development** on your assigned features

## Getting Help

- **Documentation Issues:** Open an issue on GitHub
- **Technical Questions:** Ask in team chat or Slack
- **Bug Reports:** Use the GitHub issue template

---

**Happy Coding! 🚀**
