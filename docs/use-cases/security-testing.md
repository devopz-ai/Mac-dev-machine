# Security Testing Guide

Tools for network analysis, penetration testing, and security research.

## Tool Stack

| Category | Tools |
|----------|-------|
| Packet Capture | Wireshark, tcpdump |
| Port Scanning | nmap |
| HTTP Proxy | mitmproxy, Burp Suite* |
| SSL/TLS | mkcert, openssl |
| Network Debug | telnet, mtr, curl |

`*` = Manual installation required

---

## Network Analysis

### Wireshark

```bash
# Launch
open -a Wireshark

# Capture on interface
# Select interface → Start capture

# Common filters:
# http                    - HTTP traffic only
# tcp.port == 443         - HTTPS traffic
# ip.addr == 192.168.1.1  - Specific IP
# dns                     - DNS queries
# tcp.flags.syn == 1      - TCP SYN packets
```

### tcpdump (CLI)

```bash
# Capture all traffic
sudo tcpdump -i en0

# Capture specific port
sudo tcpdump -i en0 port 80

# Capture to file
sudo tcpdump -i en0 -w capture.pcap

# Read capture file
tcpdump -r capture.pcap

# Filter by host
sudo tcpdump -i en0 host 192.168.1.1
```

---

## Port Scanning

### nmap

```bash
# Basic scan
nmap 192.168.1.1

# Scan specific ports
nmap -p 22,80,443 192.168.1.1

# Scan port range
nmap -p 1-1000 192.168.1.1

# Service detection
nmap -sV 192.168.1.1

# OS detection
nmap -O 192.168.1.1

# Full scan (slow)
nmap -A 192.168.1.1

# Scan network range
nmap 192.168.1.0/24

# Fast scan
nmap -F 192.168.1.1

# Output to file
nmap -oN output.txt 192.168.1.1
```

**Common scan types:**

| Flag | Description |
|------|-------------|
| -sT | TCP connect scan |
| -sS | TCP SYN scan (requires root) |
| -sU | UDP scan |
| -sP | Ping scan (host discovery) |

---

## HTTP Proxy

### mitmproxy

```bash
# Start proxy
mitmproxy

# Web interface
mitmweb
# → http://localhost:8081

# Proxy runs on :8080
# Configure browser/device to use localhost:8080

# Save traffic
mitmdump -w traffic.flow

# Replay traffic
mitmdump -r traffic.flow
```

**Navigation:**
- `j/k` - Move down/up
- `Enter` - View details
- `q` - Back/quit
- `f` - Set filter
- `i` - Intercept filter

### SSL/TLS Interception

```bash
# Install mitmproxy CA certificate
# 1. Start mitmproxy
# 2. Configure device to use proxy
# 3. Visit http://mitm.it
# 4. Install certificate for your OS
```

---

## SSL/TLS Tools

### mkcert (Local HTTPS)

```bash
# Install CA
mkcert -install

# Create certificate
mkcert localhost 127.0.0.1 ::1

# Creates:
# - localhost+2.pem
# - localhost+2-key.pem

# Use with Node.js
# const https = require('https');
# const fs = require('fs');
# https.createServer({
#   key: fs.readFileSync('localhost+2-key.pem'),
#   cert: fs.readFileSync('localhost+2.pem')
# }, app).listen(443);
```

### openssl

```bash
# Check certificate
openssl s_client -connect example.com:443

# View certificate details
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -text

# Check expiration
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates

# Generate self-signed cert
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

---

## Network Diagnostics

### telnet

```bash
# Test port connectivity
telnet example.com 80
telnet example.com 443

# Test SMTP
telnet mail.example.com 25
```

### mtr (traceroute + ping)

```bash
# Trace route with stats
mtr example.com

# Report mode
mtr -r -c 10 example.com
```

### curl (HTTP debugging)

```bash
# Verbose output
curl -v https://example.com

# Show headers only
curl -I https://example.com

# Follow redirects
curl -L https://example.com

# Ignore SSL errors (testing only!)
curl -k https://self-signed.example.com

# Timing info
curl -w "@curl-format.txt" -o /dev/null -s https://example.com
```

---

## ngrok (Expose Local Server)

```bash
# Expose local port
ngrok http 3000

# With custom subdomain (paid)
ngrok http -subdomain=myapp 3000

# Inspect traffic
# → http://localhost:4040
```

---

## Security Checks

### Check Open Ports (Your Machine)

```bash
# List listening ports
lsof -i -P | grep LISTEN

# Specific port
lsof -i :8080

# netstat alternative
netstat -an | grep LISTEN
```

### DNS Lookup

```bash
# Basic lookup
nslookup example.com
dig example.com

# Specific record types
dig example.com MX
dig example.com TXT
dig example.com NS

# Reverse lookup
dig -x 93.184.216.34
```

---

## Security Testing Workflow

### Web Application Testing

```bash
# 1. Reconnaissance
nmap -sV target.com
dig target.com

# 2. Set up proxy
mitmproxy

# 3. Configure browser to use proxy
# 4. Browse target, analyze traffic

# 5. Test for common issues
# - SQL injection
# - XSS
# - Authentication bypass
# - Sensitive data exposure
```

### API Security Testing

```bash
# Test authentication
http GET api.target.com/admin  # Should 401

# Test with stolen/expired token
http GET api.target.com/me Authorization:"Bearer expired-token"

# Test rate limiting
for i in {1..100}; do
  http GET api.target.com/endpoint
done
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied (nmap) | Run with `sudo` |
| Wireshark no interfaces | Grant permission in System Preferences |
| mitmproxy SSL errors | Install CA certificate |
| Connection refused | Check firewall, service running |
| Port scan blocked | Target may have IDS/IPS |
