# n8n Production Setup dengan MCP Integration

## 🎯 Arsitektur Setup

Setup ini mencakup:
- **n8n Main Instance**: Web interface dan webhook handler
- **n8n Workers**: Scalable worker instances untuk queue processing
- **PostgreSQL**: Database utama untuk menyimpan data n8n
- **Redis**: Message broker untuk queue mode dan caching
- **n8n-MCP**: Model Context Protocol server untuk AI integration

## 📁 Struktur File

```
n8n-hotel/
├── docker-compose.yml      # Konfigurasi Docker Compose utama
├── .env                    # Environment variables
├── scaling.sh              # Script untuk scaling workers
├── MCP_INTEGRATION_COMPLETE.md  # Dokumentasi MCP
├── pgbouncer/             # Konfigurasi PgBouncer (untuk future use)
├── postgres/              # PostgreSQL initialization
├── n8n-mcp/              # n8n-MCP source code
└── volumes/              # Data persistence directories
    ├── n8n/
    ├── postgres/
    ├── redis/
    └── n8n-mcp/
```

## 🚀 Cara Menjalankan

1. **Pastikan Docker sudah terinstall**
2. **Jalankan setup**:
   ```bash
   docker-compose up -d
   ```

3. **Akses n8n**:
   - URL: http://192.168.5.12:5678
   - Login: edp.jbbk@gmail.com / Password@2021

## 🔧 Scaling Workers

Gunakan script scaling.sh:
```bash
./scaling.sh up 3    # Scale up ke 3 workers
./scaling.sh down 1  # Scale down ke 1 worker
./scaling.sh status  # Check status
```

## 🤖 n8n-MCP Integration

MCP server running di port 3000 dengan:
- 525+ n8n nodes documentation
- 99% node properties coverage
- 263 AI-capable nodes
- Auth Token: aMG5o6vdVkPusq+GrxMh8NQ8q1NdYXiPstLf+/PUk1c=

## 📋 Environment Variables

Semua konfigurasi tersimpan di file `.env`:
- Database credentials
- Redis password
- n8n authentication
- MCP server configuration

## 🛠️ Troubleshooting

1. **Check service status**: `docker-compose ps`
2. **View logs**: `docker-compose logs service_name`
3. **Restart services**: `docker-compose restart`

## 🎉 Status Setup

- ✅ n8n Main: http://192.168.5.12:5678
- ✅ n8n Worker: Queue processing
- ✅ PostgreSQL: Database utama
- ✅ Redis: Message broker
- ✅ n8n-MCP: http://192.168.5.12:3000

**Setup berhasil dan siap digunakan!** 🚀