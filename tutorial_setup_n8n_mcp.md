# Tutorial Setup n8n Production dengan MCP Integration

## 🎯 Arsitektur Setup

Setup ini mencakup:
- **n8n Main Instance**: Web interface dan webhook handler
- **n8n Workers**: Scalable worker instances untuk queue processing
- **PostgreSQL**: Database utama untuk menyimpan data n8n
- **Redis**: Message broker untuk queue mode dan caching
- **PgBouncer**: Connection pooling untuk PostgreSQL
- **n8n-MCP**: Model Context Protocol server untuk AI integration

## 📋 Prerequisites

1. **Server Requirements**:
   - Ubuntu 20.04+ atau CentOS 8+
   - RAM minimal 4GB (recommended 8GB+)
   - Storage minimal 50GB
   - Docker dan Docker Compose terinstall

2. **Install Docker**:
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   
   # Add user to docker group
   sudo usermod -aG docker $USER
   newgrp docker
   ```

## 🚀 Step-by-Step Setup

### Step 1: Clone Repository dan Setup Folder

```bash
# Clone repository
git clone https://github.com/gzjbbk/n8n-hotel.git
cd n8n-hotel

# Create volume directories
mkdir -p volumes/{n8n,postgres,redis,n8n-mcp}
chmod 755 volumes/*
```

### Step 2: Setup Environment Variables

Buat file `.env`:

```bash
# Database Configuration
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=n8n_password_2024
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis Configuration
REDIS_PASSWORD=redis_password_2024

# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=edp.jbbk@gmail.com
N8N_BASIC_AUTH_PASSWORD=Password@2021

# n8n Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n_password_2024

# n8n Queue Mode
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379
QUEUE_BULL_REDIS_PASSWORD=redis_password_2024
QUEUE_BULL_REDIS_DB=0

# n8n Worker Configuration
N8N_ENCRYPTION_KEY=your_encryption_key_here_32_chars
EXECUTIONS_MODE=queue
EXECUTIONS_PROCESS=main

# Remote Access Configuration (PENTING!)
N8N_SECURE_COOKIE=false
N8N_EDITOR_BASE_URL=http://YOUR_SERVER_IP:5678
WEBHOOK_URL=http://YOUR_SERVER_IP:5678/
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# n8n-MCP Configuration
MCP_DATABASE_URL=sqlite:///app/data/n8n_nodes.db
MCP_AUTH_TOKEN=aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=
MCP_PORT=3000

# n8n API Configuration (untuk MCP akses n8n)
N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3Njc5ODRmOS1hYzJkLTRiYmQtODU2MS04MmJjZjU5NjcxYzkiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzUyMDMxMTUxfQ.YjJQhUYDjDElZnQZEzQMN1cs_LlvwS7L58FE4mm9dvM
N8N_API_BASE_URL=http://n8n:5678

# PgBouncer Configuration
PGBOUNCER_DATABASE_URL=postgres://n8n:n8n_password_2024@postgres:5432/n8n
PGBOUNCER_POOL_MODE=transaction
PGBOUNCER_MAX_CLIENT_CONN=100
PGBOUNCER_DEFAULT_POOL_SIZE=25
```

### Step 3: Setup Docker Compose

File `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./volumes/postgres:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}']
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - ./volumes/redis:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ['CMD', 'redis-cli', '--raw', 'incr', 'ping']
      interval: 10s
      timeout: 5s
      retries: 5

  pgbouncer:
    image: pgbouncer/pgbouncer:latest
    restart: unless-stopped
    environment:
      DATABASE_URL: ${PGBOUNCER_DATABASE_URL}
      POOL_MODE: ${PGBOUNCER_POOL_MODE}
      MAX_CLIENT_CONN: ${PGBOUNCER_MAX_CLIENT_CONN}
      DEFAULT_POOL_SIZE: ${PGBOUNCER_DEFAULT_POOL_SIZE}
    ports:
      - "6432:6432"
    volumes:
      - ./pgbouncer/pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini
    depends_on:
      postgres:
        condition: service_healthy

  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    environment:
      - DB_TYPE=${DB_TYPE}
      - DB_POSTGRESDB_HOST=${DB_POSTGRESDB_HOST}
      - DB_POSTGRESDB_PORT=${DB_POSTGRESDB_PORT}
      - DB_POSTGRESDB_DATABASE=${DB_POSTGRESDB_DATABASE}
      - DB_POSTGRESDB_USER=${DB_POSTGRESDB_USER}
      - DB_POSTGRESDB_PASSWORD=${DB_POSTGRESDB_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - QUEUE_BULL_REDIS_HOST=${QUEUE_BULL_REDIS_HOST}
      - QUEUE_BULL_REDIS_PORT=${QUEUE_BULL_REDIS_PORT}
      - QUEUE_BULL_REDIS_PASSWORD=${QUEUE_BULL_REDIS_PASSWORD}
      - QUEUE_BULL_REDIS_DB=${QUEUE_BULL_REDIS_DB}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - EXECUTIONS_MODE=${EXECUTIONS_MODE}
      - EXECUTIONS_PROCESS=${EXECUTIONS_PROCESS}
      - N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}
      - N8N_EDITOR_BASE_URL=${N8N_EDITOR_BASE_URL}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=${N8N_PORT}
      - N8N_PROTOCOL=${N8N_PROTOCOL}
    ports:
      - "5678:5678"
    volumes:
      - ./volumes/n8n:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:5678/healthz || exit 1']
      interval: 30s
      timeout: 10s
      retries: 3

  n8n-worker:
    image: n8nio/n8n:latest
    restart: unless-stopped
    command: n8n worker
    environment:
      - DB_TYPE=${DB_TYPE}
      - DB_POSTGRESDB_HOST=${DB_POSTGRESDB_HOST}
      - DB_POSTGRESDB_PORT=${DB_POSTGRESDB_PORT}
      - DB_POSTGRESDB_DATABASE=${DB_POSTGRESDB_DATABASE}
      - DB_POSTGRESDB_USER=${DB_POSTGRESDB_USER}
      - DB_POSTGRESDB_PASSWORD=${DB_POSTGRESDB_PASSWORD}
      - QUEUE_BULL_REDIS_HOST=${QUEUE_BULL_REDIS_HOST}
      - QUEUE_BULL_REDIS_PORT=${QUEUE_BULL_REDIS_PORT}
      - QUEUE_BULL_REDIS_PASSWORD=${QUEUE_BULL_REDIS_PASSWORD}
      - QUEUE_BULL_REDIS_DB=${QUEUE_BULL_REDIS_DB}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - EXECUTIONS_MODE=${EXECUTIONS_MODE}
    volumes:
      - ./volumes/n8n:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    deploy:
      replicas: 2

  n8n-mcp:
    build: ./n8n-mcp
    restart: unless-stopped
    environment:
      - DATABASE_URL=${MCP_DATABASE_URL}
      - AUTH_TOKEN=${MCP_AUTH_TOKEN}
      - PORT=${MCP_PORT}
      - N8N_API_KEY=${N8N_API_KEY}
      - N8N_API_BASE_URL=${N8N_API_BASE_URL}
    ports:
      - "3000:3000"
    volumes:
      - n8n-mcp-data:/app/data
    depends_on:
      n8n:
        condition: service_healthy
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:3000/health || exit 1']
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  n8n-mcp-data:
    driver: local
```

### Step 4: Setup PostgreSQL Initialization

Buat file `postgres/init.sql`:

```sql
-- Create n8n database if not exists
CREATE DATABASE IF NOT EXISTS n8n;

-- Create user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'n8n') THEN
        CREATE USER n8n WITH PASSWORD 'n8n_password_2024';
    END IF;
END
$$;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
GRANT ALL ON SCHEMA public TO n8n;
```

### Step 5: Setup PgBouncer Configuration

Buat file `pgbouncer/pgbouncer.ini`:

```ini
[databases]
n8n = host=postgres port=5432 dbname=n8n user=n8n password=n8n_password_2024

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
unix_socket_dir = /tmp
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres
stats_users = postgres
pool_mode = transaction
server_reset_query = DISCARD ALL
max_client_conn = 100
default_pool_size = 25
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
```

### Step 6: Setup n8n-MCP Integration

```bash
# Clone n8n-MCP repository
git clone https://github.com/czlonkowski/n8n-mcp.git
cd n8n-mcp

# Build MCP dengan dependencies minimal
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# Create data directory
RUN mkdir -p /app/data

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose port
EXPOSE 3000

# Start server
CMD ["npm", "start"]
EOF

# Build Docker image
docker build -t n8n-mcp .
cd ..
```

### Step 7: Setup Worker Scaling Script

Buat file `scaling.sh`:

```bash
#!/bin/bash

# Script untuk scaling n8n workers
# Usage: ./scaling.sh [up|down] [number]

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
```

```bash
chmod +x scaling.sh
```

### Step 8: Deploy Setup

```bash
# PENTING: Edit .env file dengan IP server Anda
sed -i 's/YOUR_SERVER_IP/192.168.5.12/g' .env

# Generate encryption key 32 karakter
ENCRYPTION_KEY=$(openssl rand -hex 16)
sed -i "s/your_encryption_key_here_32_chars/$ENCRYPTION_KEY/g" .env

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# PENTING: Test akses dari komputer lain
# Pastikan bisa diakses dari jaringan lokal
curl -I http://192.168.5.12:5678

# View logs jika ada masalah
docker-compose logs -f n8n
```

### Step 9: Generate n8n API Key

1. **Akses n8n**: http://192.168.5.12:5678
2. **Login**: edp.jbbk@gmail.com / Password@2021
3. **Buat API Key**:
   - Masuk ke Settings → API Keys
   - Klik "Create API Key"
   - Copy API key yang dihasilkan
   - Update file `.env` dengan API key baru:
   ```bash
   N8N_API_KEY=your_new_api_key_here
   ```
4. **Restart MCP service**:
   ```bash
   docker-compose restart n8n-mcp
   ```

### Step 10: Test Integration

1. **Web Interface**: http://192.168.5.12:5678
2. **MCP Server**: http://192.168.5.12:3000
3. **Test MCP dengan n8n API**:
   ```bash
   # Test MCP health
   curl -H "Authorization: Bearer aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=" http://192.168.5.12:3000/health
   
   # Test MCP akses n8n
   curl -H "Authorization: Bearer aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=" http://192.168.5.12:3000/nodes
   ```

## 🔧 Operasional

### Scaling Workers

```bash
# Scale up workers
./scaling.sh up 5

# Scale down workers
./scaling.sh down 2

# Check status
./scaling.sh status
```

### Monitoring

```bash
# Check service health
docker-compose ps

# View logs
docker-compose logs service_name

# Monitor resource usage
docker stats

# Check Redis queue
docker exec -it n8n-hotel-redis-1 redis-cli -a redis_password_2024 monitor
```

### Backup dan Recovery

```bash
# Backup PostgreSQL
docker exec n8n-hotel-postgres-1 pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Backup n8n data
tar -czf n8n_backup_$(date +%Y%m%d).tar.gz volumes/n8n/

# Restore PostgreSQL
docker exec -i n8n-hotel-postgres-1 psql -U n8n n8n < backup_20250109.sql
```

## 🛠️ Troubleshooting

### Common Issues

1. **n8n tidak bisa diakses dari komputer lain** (MASALAH UMUM):
   ```bash
   # Check firewall - buka port yang diperlukan
   sudo ufw allow 5678
   sudo ufw allow 3000
   
   # PENTING: Pastikan environment variables benar
   grep -E "N8N_SECURE_COOKIE|N8N_HOST|N8N_EDITOR_BASE_URL" .env
   
   # Harus seperti ini:
   # N8N_SECURE_COOKIE=false
   # N8N_HOST=0.0.0.0
   # N8N_EDITOR_BASE_URL=http://192.168.5.12:5678
   
   # Restart n8n jika ada perubahan
   docker-compose restart n8n
   
   # Test dari server lokal
   curl -I http://localhost:5678
   
   # Test dari komputer lain (ganti IP)
   curl -I http://192.168.5.12:5678
   ```

2. **Worker tidak memproses queue**:
   ```bash
   # Check Redis connection
   docker exec n8n-hotel-redis-1 redis-cli -a redis_password_2024 ping
   
   # Check worker logs
   docker-compose logs n8n-worker
   ```

3. **Database connection issues**:
   ```bash
   # Check PostgreSQL
   docker exec n8n-hotel-postgres-1 psql -U n8n -d n8n -c "SELECT 1"
   
   # Check PgBouncer
   docker exec n8n-hotel-pgbouncer-1 psql -h localhost -p 6432 -U n8n -d n8n -c "SELECT 1"
   ```

4. **MCP server tidak responding**:
   ```bash
   # Check MCP logs
   docker-compose logs n8n-mcp
   
   # Test MCP endpoint
   curl -H "Authorization: Bearer aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=" http://192.168.5.12:3000/health
   
   # Test MCP akses ke n8n
   curl -H "Authorization: Bearer aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=" http://192.168.5.12:3000/workflows
   ```

5. **MCP tidak bisa akses n8n API**:
   ```bash
   # Check n8n API key di environment
   docker exec n8n-hotel-n8n-mcp-1 printenv | grep N8N_API
   
   # Test n8n API langsung
   curl -H "X-N8N-API-KEY: your_api_key_here" http://192.168.5.12:5678/api/v1/workflows
   
   # Regenerate API key jika perlu
   # Login ke n8n → Settings → API Keys → Create new key
   ```

### Performance Tuning

1. **PostgreSQL Optimization**:
   ```sql
   -- Connect to PostgreSQL
   ALTER SYSTEM SET shared_buffers = '256MB';
   ALTER SYSTEM SET effective_cache_size = '1GB';
   ALTER SYSTEM SET maintenance_work_mem = '64MB';
   ALTER SYSTEM SET checkpoint_completion_target = 0.9;
   SELECT pg_reload_conf();
   ```

2. **Redis Optimization**:
   ```bash
   # Add to docker-compose.yml redis service
   command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 512mb --maxmemory-policy allkeys-lru
   ```

## 📋 Maintenance

### Regular Tasks

1. **Weekly**:
   - Check disk space
   - Review logs for errors
   - Backup database

2. **Monthly**:
   - Update Docker images
   - Clean unused Docker resources
   - Review performance metrics

3. **Quarterly**:
   - Review and rotate passwords
   - Update system packages
   - Performance optimization review

### Update Procedure

```bash
# Pull latest images
docker-compose pull

# Stop services
docker-compose down

# Start with new images
docker-compose up -d

# Verify all services
docker-compose ps
```

## 🎉 Selesai!

Setup n8n production dengan MCP integration sudah complete dan siap digunakan:

- ✅ n8n Main Instance: http://192.168.5.12:5678
- ✅ n8n Workers: Scalable queue processing
- ✅ PostgreSQL: Database dengan PgBouncer pooling
- ✅ Redis: Message broker dan caching
- ✅ n8n-MCP: AI integration server
- ✅ **Remote Access**: Bisa diakses dari komputer lain di jaringan

## 🔍 Checklist Akses Remote

**Sebelum mengatakan "tidak bisa diakses", pastikan:**

1. ✅ `N8N_SECURE_COOKIE=false` di .env
2. ✅ `N8N_HOST=0.0.0.0` di .env  
3. ✅ `N8N_EDITOR_BASE_URL=http://192.168.5.12:5678` di .env
4. ✅ Port 5678 dan 3000 terbuka di firewall
5. ✅ Container n8n running (`docker-compose ps`)
6. ✅ Test akses: `curl -I http://192.168.5.12:5678`

**Jika masih tidak bisa akses:**
```bash
# Restart semua service
docker-compose restart

# Check logs
docker-compose logs n8n

# Check IP binding
docker exec n8n-hotel-n8n-1 netstat -tlnp | grep 5678
```

**Total setup time**: ~30 menit  
**Remote access**: ✅ Sudah dikonfigurasi untuk akses jaringan lokal  
**Scalable**: Ya (horizontal scaling workers)  
**Siap pakai**: Ya untuk environment jaringan lokal