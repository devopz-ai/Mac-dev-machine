# Data Engineering Guide

Tools and workflows for databases, data pipelines, and analytics.

## Tool Stack

| Category | Tools |
|----------|-------|
| SQL DBs | PostgreSQL, MySQL, SQLite |
| NoSQL | Redis, MongoDB |
| GUI Clients | DBeaver, TablePlus |
| CLI Clients | pgcli, mycli, litecli |
| Python | pandas, SQLAlchemy |

---

## Database Setup

### PostgreSQL

```bash
# Start service
brew services start postgresql@16

# Connect
psql -U postgres

# Create database
createdb myapp

# Import SQL file
psql -U postgres -d myapp < dump.sql
```

### MySQL

```bash
# Start service
brew services start mysql

# Connect
mysql -u root

# Create database
mysql -u root -e "CREATE DATABASE myapp"
```

### Redis

```bash
# Start service
brew services start redis

# Connect
redis-cli

# Basic commands
SET key "value"
GET key
HSET user:1 name "John"
HGET user:1 name
```

---

## CLI Clients (Enhanced)

### pgcli (PostgreSQL)

```bash
pgcli -U postgres -d myapp

# Features:
# - Auto-completion
# - Syntax highlighting
# - Multi-line editing
# - History search (Ctrl+R)
```

### mycli (MySQL)

```bash
mycli -u root myapp
```

### litecli (SQLite)

```bash
litecli mydb.sqlite
```

---

## GUI Clients

### DBeaver (Free)

```bash
open -a DBeaver
```

**Setup Connection:**
1. Database → New Connection
2. Select database type
3. Enter host, port, user, password
4. Test Connection → Finish

### TablePlus (Paid, Better UX)

```bash
open -a TablePlus
```

---

## Python Data Stack

### SQLAlchemy

```python
from sqlalchemy import create_engine, text

# Connect
engine = create_engine("postgresql://user:pass@localhost/myapp")

# Query
with engine.connect() as conn:
    result = conn.execute(text("SELECT * FROM users"))
    for row in result:
        print(row)
```

### pandas

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql://user:pass@localhost/myapp")

# Read from SQL
df = pd.read_sql("SELECT * FROM users", engine)

# Write to SQL
df.to_sql("users_backup", engine, if_exists="replace", index=False)

# Read CSV
df = pd.read_csv("data.csv")

# Basic operations
df.head()
df.describe()
df.groupby("category").sum()
df.merge(df2, on="id")
```

---

## Database with Docker

### docker-compose.yml

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: pass

volumes:
  pgdata:
```

```bash
docker-compose up -d
docker-compose exec postgres psql -U user -d myapp
```

---

## Common SQL Patterns

### CRUD Operations

```sql
-- Create
INSERT INTO users (name, email) VALUES ('John', 'john@test.com');

-- Read
SELECT * FROM users WHERE id = 1;

-- Update
UPDATE users SET name = 'Jane' WHERE id = 1;

-- Delete
DELETE FROM users WHERE id = 1;
```

### Joins

```sql
-- Inner join
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;

-- Left join
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
```

### Aggregations

```sql
SELECT
  category,
  COUNT(*) as count,
  SUM(amount) as total,
  AVG(amount) as average
FROM orders
GROUP BY category
HAVING SUM(amount) > 1000
ORDER BY total DESC;
```

---

## Migrations

### Alembic (Python)

```bash
# Install
pip install alembic

# Initialize
alembic init migrations

# Create migration
alembic revision --autogenerate -m "Add users table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Prisma (Node.js)

```bash
# Initialize
npx prisma init

# Create migration
npx prisma migrate dev --name init

# Apply to production
npx prisma migrate deploy

# Generate client
npx prisma generate
```

---

## Backup & Restore

### PostgreSQL

```bash
# Backup
pg_dump -U user myapp > backup.sql
pg_dump -U user -Fc myapp > backup.dump  # Compressed

# Restore
psql -U user myapp < backup.sql
pg_restore -U user -d myapp backup.dump
```

### MySQL

```bash
# Backup
mysqldump -u root myapp > backup.sql

# Restore
mysql -u root myapp < backup.sql
```

---

## Performance

### PostgreSQL

```sql
-- Explain query plan
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@test.com';

-- Create index
CREATE INDEX idx_users_email ON users(email);

-- Show running queries
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

### Redis

```bash
# Monitor commands
redis-cli MONITOR

# Memory usage
redis-cli INFO memory

# Slow log
redis-cli SLOWLOG GET 10
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Start service: `brew services start postgresql@16` |
| Auth failed | Check user/password in pg_hba.conf |
| Database not found | Create: `createdb myapp` |
| Port in use | Check: `lsof -i :5432` |
| Slow queries | Add indexes, EXPLAIN ANALYZE |
