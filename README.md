# 🛡 MQTT TLS Certificate Generation & Usage Guide

This script creates a self-signed Certificate Authority (CA), and generates server and client certificates to enable **SSL/TLS encryption** with the Eclipse Mosquitto MQTT broker.

---

## 🔧 Usage Instructions

### 1. Run the Script
Make the script executable and run it:

```bash
chmod +x generate_mqtt_certs.sh
./generate_mqtt_certs.sh
```

You will be prompted for:
- CA password (hidden input)
- Country code (default: DE)
- Validity period in years (default: 10)
- MQTT server name or IP
- Client name (default: alamos)

The script will generate all files in the `./certs/` directory.

---

## 📁 File Structure

```
certs/
  ├── ca.crt         # CA certificate (public)
  ├── ca.key         # CA private key (keep secure)
  ├── server.crt     # Server certificate (signed by CA)
  ├── server.key     # Server private key
  ├── client.crt     # Client certificate (signed by CA)
  └── client.key     # Client private key
```

---

## 🐳 Docker Setup (Mosquitto with TLS)

### 2. Docker Directory Layout

Create a directory structure like:

```
mosquitto-docker/
├── config/
│   └── mosquitto.conf
├── data/
├── log/
└── certs/                    # Copy cert files here
    ├── ca.crt
    ├── server.crt
    └── server.key
```

### 3. Copy Files

Copy generated files to `mosquitto-docker/certs/`:

```bash
cp certs/server.crt certs/server.key certs/ca.crt mosquitto-docker/certs/
```

### 4. Create `mosquitto.conf`

Create `mosquitto-docker/config/mosquitto.conf`:

```conf
listener 8883
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate true
use_identity_as_username true
allow_anonymous false
```

### 5. Create `docker-compose.yml`

Example Docker Compose:

```yaml
version: '3'

services:
  mosquitto:
    image: eclipse-mosquitto
    container_name: mosquitto
    volumes:
      - ./config:/mosquitto/config
      - ./data:/mosquitto/data
      - ./log:/mosquitto/log
      - ./certs:/mosquitto/certs
    ports:
      - "8883:8883"
    restart: unless-stopped
```

Start with:

```bash
docker-compose up -d
```

---

## ✅ Connecting a Client

### Using `mosquitto_pub`:

```bash
mosquitto_pub -h <broker-ip> -p 8883 \
  --cafile certs/ca.crt \
  --cert certs/client.crt \
  --key certs/client.key \
  -t "test/topic" -m "Hello over TLS"
```

### Using `mosquitto_sub`:

```bash
mosquitto_sub -h <broker-ip> -p 8883 \
  --cafile certs/ca.crt \
  --cert certs/client.crt \
  --key certs/client.key \
  -t "test/topic"
```

---

## 🔐 Notes
- The CA key (`ca.key`) should be kept secure and never shared.
- The `client.crt` and `client.key` can be distributed to trusted clients for mutual TLS.
- Change `require_certificate` to `false` if you want to allow TLS without client certs.

