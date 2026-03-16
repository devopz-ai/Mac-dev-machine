# API Development Guide

Tools and workflows for building, testing, and documenting APIs.

## Tool Stack

| Task | Tools |
|------|-------|
| Testing GUI | Postman, Insomnia, Bruno |
| CLI Testing | httpie, curl |
| JSON Processing | jq, fx |
| Documentation | Swagger/OpenAPI |
| Load Testing | k6, wrk |

---

## Quick Testing

### httpie (Recommended CLI)

```bash
# GET request
http GET api.example.com/users

# With headers
http GET api.example.com/users Authorization:"Bearer token"

# POST JSON
http POST api.example.com/users name=John email=john@test.com

# POST with JSON body
http POST api.example.com/users < data.json

# Form data
http -f POST api.example.com/upload file@image.png

# Download file
http --download GET api.example.com/file.pdf
```

### curl (Built-in)

```bash
# GET
curl https://api.example.com/users

# POST JSON
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@test.com"}'

# With auth
curl -H "Authorization: Bearer token" https://api.example.com/users

# Verbose output
curl -v https://api.example.com/users
```

---

## JSON Processing

### jq Basics

```bash
# Pretty print
echo '{"name":"John"}' | jq '.'

# Get field
echo '{"name":"John"}' | jq '.name'

# Array operations
echo '[1,2,3]' | jq '.[0]'     # First element
echo '[1,2,3]' | jq '.[-1]'    # Last element
echo '[1,2,3]' | jq 'length'   # Array length

# Filter array
echo '[{"a":1},{"a":2}]' | jq '.[] | select(.a > 1)'

# Map/transform
echo '[{"name":"John"},{"name":"Jane"}]' | jq '.[].name'

# Combine with httpie
http GET api.example.com/users | jq '.data[].email'
```

### fx (Interactive)

```bash
# Interactive JSON explorer
echo '{"data":[1,2,3]}' | fx

# Apply transformation
echo '{"name":"John"}' | fx '.name'
```

---

## GUI Tools

### Postman

```bash
open -a Postman
```

**Key Features:**
- Collections (save/organize requests)
- Environments (dev/staging/prod variables)
- Pre-request scripts
- Tests (assertions)
- Mock servers

**Quick Tips:**
```
{{variable}}          # Use environment variable
pm.response.json()    # Access response in tests
pm.test("Status 200", () => pm.response.to.have.status(200))
```

### Bruno (Open Source Alternative)

```bash
open -a Bruno
# Or: brew install --cask bruno
```

**Advantages:**
- Git-friendly (plain text files)
- No cloud sync required
- Offline first
- Open source

### Insomnia

```bash
open -a Insomnia
```

**Key Features:**
- GraphQL support
- gRPC support
- OpenAPI import

---

## Building REST APIs

### FastAPI (Python)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class User(BaseModel):
    name: str
    email: str

users = []

@app.get("/users")
def list_users():
    return users

@app.post("/users")
def create_user(user: User):
    users.append(user)
    return user

@app.get("/users/{user_id}")
def get_user(user_id: int):
    if user_id >= len(users):
        raise HTTPException(status_code=404, detail="Not found")
    return users[user_id]

# Run: uvicorn main:app --reload
# Docs: http://localhost:8000/docs
```

### Express (Node.js)

```javascript
const express = require('express');
const app = express();
app.use(express.json());

let users = [];

app.get('/users', (req, res) => {
  res.json(users);
});

app.post('/users', (req, res) => {
  users.push(req.body);
  res.status(201).json(req.body);
});

app.get('/users/:id', (req, res) => {
  const user = users[req.params.id];
  if (!user) return res.status(404).json({ error: 'Not found' });
  res.json(user);
});

app.listen(3000);
```

---

## GraphQL

### Testing with Postman/Insomnia

```graphql
# Query
query {
  users {
    id
    name
    email
  }
}

# Mutation
mutation {
  createUser(input: { name: "John", email: "john@test.com" }) {
    id
  }
}

# With variables
query GetUser($id: ID!) {
  user(id: $id) {
    name
  }
}
# Variables: {"id": "1"}
```

### CLI Testing

```bash
# Using curl
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ users { id name } }"}'
```

---

## Authentication Testing

### JWT

```bash
# Decode JWT (without verification)
echo "eyJhbG..." | cut -d. -f2 | base64 -d | jq '.'

# Test with token
http GET api.example.com/me Authorization:"Bearer eyJhbG..."
```

### OAuth2 Flow

```bash
# 1. Get authorization code (browser)
# 2. Exchange for token
http POST auth.example.com/token \
  grant_type=authorization_code \
  code=AUTH_CODE \
  client_id=CLIENT_ID \
  client_secret=CLIENT_SECRET

# 3. Use access token
http GET api.example.com/me Authorization:"Bearer ACCESS_TOKEN"
```

---

## Load Testing

### k6

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,           // Virtual users
  duration: '30s',   // Test duration
};

export default function () {
  const res = http.get('http://localhost:3000/api/users');
  check(res, { 'status was 200': (r) => r.status === 200 });
  sleep(1);
}
```

```bash
k6 run load-test.js
```

### wrk

```bash
# 10 connections, 2 threads, 30 seconds
wrk -t2 -c10 -d30s http://localhost:3000/api/users
```

---

## API Documentation

### OpenAPI/Swagger

```yaml
# openapi.yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
```

**FastAPI generates this automatically at `/docs`**

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CORS errors | Add CORS headers on server |
| 401 Unauthorized | Check token, expiration |
| 403 Forbidden | Check permissions |
| 404 Not Found | Verify URL/endpoint |
| 500 Server Error | Check server logs |
| Connection refused | Verify server is running |
