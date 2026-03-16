# Web Development Guide

Tools and workflows for frontend, backend, and full-stack web development.

## Tool Stack

| Layer | Tools |
|-------|-------|
| Frontend | Node.js, npm/pnpm, VS Code, Chrome DevTools |
| Backend | Python/Node/Go, Docker, PostgreSQL/Redis |
| DevOps | Docker Compose, nginx, GitHub Actions |

---

## Frontend Development

### React/Next.js Setup

```bash
# Create React app
npx create-react-app myapp
cd myapp && npm start

# Create Next.js app
npx create-next-app@latest myapp
cd myapp && npm run dev
```

### Vue/Nuxt Setup

```bash
# Create Vue app
npm create vue@latest myapp
cd myapp && npm install && npm run dev

# Create Nuxt app
npx nuxi init myapp
cd myapp && npm install && npm run dev
```

### Essential VS Code Extensions

```bash
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension bradlc.vscode-tailwindcss
code --install-extension dsznajder.es7-react-js-snippets
```

### Debugging

| Task | Tool/Method |
|------|-------------|
| React components | React DevTools (Chrome extension) |
| Network requests | Chrome DevTools → Network tab |
| Console errors | Chrome DevTools → Console |
| State inspection | Redux DevTools / Vue DevTools |

---

## Backend Development

### Python + FastAPI

```bash
# Setup
mkdir backend && cd backend
python -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn sqlalchemy

# Create main.py
cat > main.py << 'EOF'
from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}
EOF

# Run
uvicorn main:app --reload
# → http://localhost:8000
# → http://localhost:8000/docs (Swagger UI)
```

### Node + Express

```bash
# Setup
mkdir backend && cd backend
npm init -y
npm install express cors dotenv

# Create index.js
cat > index.js << 'EOF'
const express = require('express');
const app = express();
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Hello World' });
});

app.listen(3000, () => console.log('Server running on 3000'));
EOF

# Run
node index.js
```

### Go + Gin

```bash
# Setup
mkdir backend && cd backend
go mod init backend
go get github.com/gin-gonic/gin

# Create main.go
cat > main.go << 'EOF'
package main

import "github.com/gin-gonic/gin"

func main() {
    r := gin.Default()
    r.GET("/", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "Hello World"})
    })
    r.Run(":8080")
}
EOF

# Run
go run main.go
```

---

## Full Stack with Docker

### docker-compose.yml

```yaml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Commands

```bash
docker-compose up -d          # Start all services
docker-compose logs -f        # View logs
docker-compose down           # Stop all
docker-compose exec backend sh # Shell into container
```

---

## Database Integration

### PostgreSQL

```bash
# Start PostgreSQL
brew services start postgresql@16

# Connect
psql -U postgres

# Or use pgcli (better CLI)
pgcli -U postgres
```

### Redis

```bash
# Start Redis
brew services start redis

# Connect
redis-cli
> SET key "value"
> GET key
```

### DBeaver (GUI)

```bash
open -a DBeaver
# Connection: PostgreSQL
# Host: localhost, Port: 5432
# Database: postgres, User: postgres
```

---

## Testing

### Frontend Testing

```bash
# Jest (React)
npm test

# Cypress (E2E)
npm install -D cypress
npx cypress open
```

### Backend Testing

```bash
# Python
pip install pytest httpx
pytest

# Node
npm install -D jest supertest
npm test
```

### API Testing

```bash
# Quick test with httpie
http GET localhost:8000/api/users
http POST localhost:8000/api/users name=John email=john@test.com

# Or use Postman
open -a Postman
```

---

## Common Workflows

### Start Development

```bash
# Terminal 1: Frontend
cd frontend && npm run dev

# Terminal 2: Backend
cd backend && source .venv/bin/activate && uvicorn main:app --reload

# Terminal 3: Database
docker-compose up db
```

### Deploy Preview

```bash
# Build frontend
cd frontend && npm run build

# Build backend Docker image
cd backend && docker build -t myapp-backend .

# Run production-like
docker-compose -f docker-compose.prod.yml up
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CORS errors | Add CORS middleware to backend |
| Port in use | `lsof -i :3000` → `kill <PID>` |
| Node modules issues | `rm -rf node_modules && npm install` |
| Python import errors | Check virtual env is activated |
| DB connection refused | Ensure database is running |
