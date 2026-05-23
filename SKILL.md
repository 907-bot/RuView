---
name: ruview-project
description: >
  Use this skill whenever the user wants to build, scaffold, configure, or deploy
  a RuView-based application. RuView turns commodity WiFi signals into real-time
  spatial intelligence (human pose, vital signs, presence detection) using ESP32
  sensors and edge AI — no cameras, no cloud required.
  Triggers: "build a RuView app", "WiFi sensing project", "WiFi CSI pose detection",
  "contactless vital signs", "presence detection WiFi", "deploy RuView", "RuView
  dashboard", "WiFi DensePose project", "smart room sensing".
  Covers: project scaffolding, sensor firmware flashing, backend setup (Rust/Python),
  real-time WebSocket frontend, Docker deployment, and free cloud hosting options.
  Do NOT use for generic IoT projects unrelated to CSI/WiFi sensing, or for
  camera-based pose estimation (use a different CV skill for that).
license: MIT (same as RuView upstream)
---

# RuView — Project Creation & Free Deployment Skill

## Overview

RuView (github.com/ruvnet/RuView) is an **edge AI perception system** that uses
WiFi Channel State Information (CSI) to detect:

| Signal | Range | Latency |
|--------|-------|---------|
| Human presence / motion | Through walls | 0.012 ms |
| Body pose (17 COCO keypoints) | Single room | Real-time |
| Breathing rate | 6–30 BPM | Real-time |
| Heart rate | 40–120 BPM | Real-time |
| Multi-person tracking | 2–4 people | Real-time |

**No cameras. No wearables. No internet. Runs fully on-device.**

---

## Quick-Start Decision Tree

```
Need to start quickly?
│
├─ No hardware yet? ──► Run demo mode (Step 2A below) — works immediately
│
├─ Have ESP32 boards? ──► Flash firmware (Step 2B) then follow full guide
│
└─ Just need the dashboard? ──► Skip to Frontend section, use ws://localhost:8000/ws/pose
```

---

## Project Structures

### Minimal project (demo mode, no hardware)
```
my-ruview-app/
├── docker-compose.yml       # Pulls RuView image, sets demo mode
├── frontend/
│   ├── index.html           # Three.js dashboard
│   ├── app.js               # WebSocket client + visualization
│   └── style.css
└── README.md
```

### Full production project
```
my-ruview-app/
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
├── backend/                 # Optional custom FastAPI/Rust extensions
│   ├── main.py              # Extra REST endpoints, alerts, storage
│   └── requirements.txt
├── frontend/
│   ├── index.html
│   ├── app.js               # WebSocket + Three.js + Chart.js
│   ├── skeleton.js          # 3D pose renderer
│   ├── vitals.js            # Heart rate / breathing charts
│   └── style.css
├── firmware/                # ESP32 node config (if using hardware)
│   └── config.json
└── deploy/
    ├── fly.toml             # Fly.io free tier config
    ├── render.yaml          # Render.com free tier config
    └── railway.json         # Railway free tier config
```

---

## Step 1 — Clone RuView

```bash
git clone https://github.com/ruvnet/RuView.git
cd RuView
```

Read these two docs before anything else:
```bash
cat docs/build-guide.md    # Hardware setup, firmware flashing, build from source
cat docs/user-guide.md     # Running modes, WebSocket API, Observatory UI
```

---

## Step 2A — Run in Demo Mode (No Hardware)

No ESP32 boards required. The server simulates real CSI data so you can build
and test the full stack immediately.

### Using Docker (recommended)
```bash
# Pull and run — exposes Observatory UI + WebSocket on port 8000
docker compose up wifi-densepose

# View live logs
docker compose logs -f wifi-densepose

# Open in browser
open http://localhost:8000
```

### Without Docker (Python path)
```bash
cd RuView
pip install -r requirements.txt --break-system-packages
python -m uvicorn wifi_densepose.main:app --host 0.0.0.0 --port 8000 --reload
```

### Without Docker (Rust path — faster, recommended for production)
```bash
# Requires Rust toolchain: https://rustup.rs
cd rust-port/wifi-densepose-rs
cargo build --release
./target/release/wifi-densepose-sensing-server
# Server at http://localhost:8000
```

**Demo mode WebSocket test:**
```bash
# Confirm the WebSocket is streaming pose data
wscat -c ws://localhost:8000/ws/pose
# You'll see JSON frames like: {"keypoints": [...], "vitals": {...}, "timestamp": ...}
```

---

## Step 2B — Real Hardware Setup (ESP32 nodes)

### Hardware shopping list (per node ~$9–$15)

| Part | Notes |
|------|-------|
| ESP32-WROOM-32 or ESP32-S3 | Any dev board works |
| USB-A to Micro-USB cable | For flashing |
| 5V USB power adapter | For permanent install |
| Raspberry Pi 4 or 5 | Acts as sensing server / gateway |

### Flash ESP32 firmware

```bash
# Install PlatformIO CLI
pip install platformio --break-system-packages

# Enter firmware directory
cd RuView/firmware   # or vendor/esp32 depending on version

# Edit config — set your server IP
nano config/node_config.h
# Change: #define SERVER_IP "192.168.1.X"   ← your Pi or laptop IP

# Build and flash (with board connected via USB)
pio run --target upload --upload-port /dev/ttyUSB0

# Monitor serial output
pio device monitor --baud 115200
```

### Raspberry Pi as sensing server

```bash
# On the Pi — enable nexmon_csi for real CSI capture
# Follow: https://github.com/nexmonster/nexmon_csi
# Then run RuView server pointing at the Pi's WiFi interface
./target/release/wifi-densepose-sensing-server --interface wlan0
```

### Node placement tips
- Place 2 nodes on opposite walls for best coverage
- Nodes must be on the same WiFi network as the server
- Avoid metallic surfaces near nodes (reflections add noise)
- Height: 1.0–1.5 m from floor covers most activities

---

## Step 3 — The WebSocket API (Real-Time Data)

All visualization subscribes to this single WebSocket endpoint:

```
ws://localhost:8000/ws/pose
```

### Pose frame schema
```json
{
  "timestamp": 1716700000.123,
  "frame_id": 4821,
  "persons": [
    {
      "id": 0,
      "keypoints": [
        {"name": "nose",        "x": 0.51, "y": 0.22, "confidence": 0.91},
        {"name": "left_eye",    "x": 0.53, "y": 0.20, "confidence": 0.88},
        {"name": "right_eye",   "x": 0.49, "y": 0.20, "confidence": 0.87},
        {"name": "left_shoulder","x": 0.57, "y": 0.35, "confidence": 0.92},
        {"name": "right_shoulder","x": 0.44, "y": 0.35, "confidence": 0.91}
        // ... 17 COCO keypoints total
      ],
      "vitals": {
        "breathing_bpm": 16.2,
        "heart_rate_bpm": 72.4,
        "activity": "sitting"   // "standing" | "walking" | "lying" | "absent"
      }
    }
  ],
  "presence": true,
  "occupancy_count": 1
}
```

### REST endpoints
```
GET  /health                    → server status
GET  /api/v1/config             → current sensing config
POST /api/v1/calibrate          → trigger room calibration
GET  /api/v1/history?minutes=60 → historical frames
GET  /api/v1/environment        → RF fingerprint of room
```

---

## Step 4 — Frontend: Real-Time Visualization

### Minimal working client (vanilla JS)
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RuView Dashboard</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
  <style>
    * { margin: 0; box-sizing: border-box; }
    body { background: #0a0a0f; color: #e0e0e0; font-family: monospace; }
    #canvas-3d { width: 100%; height: 60vh; display: block; }
    #vitals { display: flex; gap: 1rem; padding: 1rem; }
    .metric { background: #111; border: 1px solid #222; padding: 1rem; flex: 1; }
    .metric .val { font-size: 2rem; font-weight: bold; color: #4ade80; }
    .metric .label { font-size: 0.75rem; color: #666; margin-top: 4px; }
    #status { position: fixed; top: 10px; right: 10px; font-size: 12px;
              background: #111; padding: 6px 12px; border-radius: 4px; }
    .dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%;
           background: #4ade80; margin-right: 6px; animation: pulse 1.5s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }
  </style>
</head>
<body>
  <div id="status"><span class="dot"></span><span id="conn-label">Connecting…</span></div>
  <canvas id="canvas-3d"></canvas>
  <div id="vitals">
    <div class="metric"><div class="val" id="bpm-breath">--</div><div class="label">Breathing BPM</div></div>
    <div class="metric"><div class="val" id="bpm-heart">--</div><div class="label">Heart Rate BPM</div></div>
    <div class="metric"><div class="val" id="activity">--</div><div class="label">Activity</div></div>
    <div class="metric"><div class="val" id="occupancy">--</div><div class="label">People</div></div>
  </div>

  <script>
  // ── Three.js skeleton setup ──────────────────────────────────────────────────
  const renderer = new THREE.WebGLRenderer({ canvas: document.getElementById('canvas-3d'), antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight * 0.6);
  renderer.setClearColor(0x0a0a0f);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(60, window.innerWidth / (window.innerHeight * 0.6), 0.1, 100);
  camera.position.set(0, 1, 3);
  camera.lookAt(0, 1, 0);

  // 17 COCO keypoint connections (skeleton edges)
  const SKELETON_EDGES = [
    [0,1],[0,2],[1,3],[2,4],          // head
    [5,6],[5,7],[7,9],[6,8],[8,10],   // arms
    [5,11],[6,12],[11,12],             // torso
    [11,13],[13,15],[12,14],[14,16]   // legs
  ];

  const joints = [];
  const bones = [];

  // Create joint spheres
  for (let i = 0; i < 17; i++) {
    const mesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.025, 8, 8),
      new THREE.MeshBasicMaterial({ color: 0x4ade80 })
    );
    scene.add(mesh);
    joints.push(mesh);
  }

  // Create bone lines
  SKELETON_EDGES.forEach(() => {
    const geo = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3()]);
    const line = new THREE.Line(geo, new THREE.LineBasicMaterial({ color: 0x22c55e }));
    scene.add(line);
    bones.push(line);
  });

  scene.add(new THREE.AmbientLight(0xffffff, 0.8));

  function updateSkeleton(keypoints) {
    // Remap normalized (0–1) coordinates to 3D space
    keypoints.forEach((kp, i) => {
      if (joints[i]) {
        joints[i].position.set(
          (kp.x - 0.5) * 2,    // x: -1 to 1
          (1 - kp.y) * 2,       // y: inverted, 0 to 2 (standing height)
          0
        );
        joints[i].visible = kp.confidence > 0.3;
      }
    });
    SKELETON_EDGES.forEach(([a, b], i) => {
      const pts = [joints[a].position.clone(), joints[b].position.clone()];
      bones[i].geometry.setFromPoints(pts);
      bones[i].geometry.attributes.position.needsUpdate = true;
      bones[i].visible = joints[a].visible && joints[b].visible;
    });
  }

  function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
  }
  animate();

  window.addEventListener('resize', () => {
    renderer.setSize(window.innerWidth, window.innerHeight * 0.6);
    camera.aspect = window.innerWidth / (window.innerHeight * 0.6);
    camera.updateProjectionMatrix();
  });

  // ── WebSocket connection ──────────────────────────────────────────────────────
  const WS_URL = 'ws://localhost:8000/ws/pose';

  function connect() {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      document.getElementById('conn-label').textContent = 'Live';
    };

    ws.onmessage = ({ data }) => {
      const frame = JSON.parse(data);
      document.getElementById('occupancy').textContent = frame.occupancy_count ?? 0;

      if (frame.persons && frame.persons.length > 0) {
        const person = frame.persons[0];
        updateSkeleton(person.keypoints);
        document.getElementById('bpm-breath').textContent =
          person.vitals?.breathing_bpm?.toFixed(1) ?? '--';
        document.getElementById('bpm-heart').textContent =
          person.vitals?.heart_rate_bpm?.toFixed(0) ?? '--';
        document.getElementById('activity').textContent =
          person.vitals?.activity ?? '--';
      }
    };

    ws.onclose = () => {
      document.getElementById('conn-label').textContent = 'Reconnecting…';
      setTimeout(connect, 2000);   // auto-reconnect
    };

    ws.onerror = () => ws.close();
  }

  connect();
  </script>
</body>
</html>
```

### Adding Chart.js vitals graph
```javascript
// Append to app.js — rolling 60-second heart rate chart
const ctx = document.getElementById('vitals-chart').getContext('2d');
const chart = new Chart(ctx, {
  type: 'line',
  data: {
    labels: [],
    datasets: [{
      label: 'Heart Rate (BPM)',
      data: [],
      borderColor: '#f97316',
      borderWidth: 1.5,
      pointRadius: 0,
      tension: 0.4
    }]
  },
  options: {
    animation: false,
    scales: { y: { min: 40, max: 120 } },
    plugins: { legend: { display: false } }
  }
});

function pushVital(bpm) {
  const now = new Date().toLocaleTimeString();
  chart.data.labels.push(now);
  chart.data.datasets[0].data.push(bpm);
  if (chart.data.labels.length > 60) {
    chart.data.labels.shift();
    chart.data.datasets[0].data.shift();
  }
  chart.update('none');  // no animation for real-time performance
}
```

### 3D point cloud viewer (advanced)
```bash
# Build and run the Rust point cloud binary (fuses camera + WiFi CSI)
cd RuView/v2
cargo build --release -p wifi-densepose-pointcloud
./target/release/ruview-pointcloud serve --bind 127.0.0.1:9880
# Open http://localhost:9880 — interactive Three.js point cloud, updates live
```

---

## Step 5 — Docker Compose (Local Full Stack)

### docker-compose.yml
```yaml
version: "3.9"
services:
  wifi-densepose:
    image: ghcr.io/ruvnet/ruview:latest
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=development
      - DEMO_MODE=true           # Remove when using real hardware
      - SECRET_KEY=changeme
    volumes:
      - ruview-data:/app/data
    restart: unless-stopped

  frontend:
    image: nginx:alpine
    ports:
      - "3000:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
    depends_on:
      - wifi-densepose
    restart: unless-stopped

volumes:
  ruview-data:
```

```bash
docker compose up -d          # Start everything
docker compose logs -f        # Follow logs
docker compose down           # Stop
docker compose down -v        # Stop + remove data volumes
```

### docker-compose.prod.yml (production override)
```yaml
version: "3.9"
services:
  wifi-densepose:
    build:
      context: .
      target: production
    environment:
      - ENVIRONMENT=production
      - DEMO_MODE=false
      - SECRET_KEY=${SECRET_KEY}
      - WORKERS=4
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
    restart: always
```

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Step 6 — Free Deployment Options

### Option A: Fly.io (Recommended — generous free tier)

**Free tier:** 3 shared VMs (256 MB RAM each), 3 GB persistent storage, 160 GB
outbound transfer/month. Supports WebSockets natively.

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login (GitHub or email — no credit card needed for free tier)
fly auth login

# Create app from RuView directory
fly launch --name my-ruview-app --region sin   # sin = Singapore, nearest for India

# Set secrets
fly secrets set SECRET_KEY=your-random-secret-here
fly secrets set ENVIRONMENT=production

# Deploy
fly deploy

# Check status
fly status
fly logs
```

**fly.toml** (place in project root)
```toml
app = "my-ruview-app"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile"

[env]
  ENVIRONMENT = "production"
  DEMO_MODE   = "true"

[http_service]
  internal_port       = 8000
  force_https         = true
  auto_stop_machines  = true
  auto_start_machines = true
  min_machines_running = 0

[[services.ports]]
  port     = 443
  handlers = ["tls", "http"]

[[vm]]
  memory = "256mb"
  cpu_kind = "shared"
  cpus = 1

[mounts]
  destination = "/app/data"
  source      = "ruview_data"
```

**WebSocket URL after deploy:**
```
wss://my-ruview-app.fly.dev/ws/pose
```

---

### Option B: Render.com

**Free tier:** 750 hours/month (one always-on service), 512 MB RAM. Spins down
after 15 min inactivity on free plan (use Fly.io if you need always-on).

**render.yaml** (place in project root for Infrastructure as Code deploy)
```yaml
services:
  - type: web
    name: ruview-sensing-server
    env: docker
    dockerfilePath: ./Dockerfile
    plan: free
    envVars:
      - key: ENVIRONMENT
        value: production
      - key: DEMO_MODE
        value: "true"
      - key: SECRET_KEY
        generateValue: true
    healthCheckPath: /health
```

```bash
# Or deploy via Render dashboard:
# 1. Go to https://render.com → New → Web Service
# 2. Connect your GitHub repo
# 3. Set Build Command: docker build -t ruview .
# 4. Set Start Command: (leave blank — reads from Dockerfile CMD)
# 5. Add env vars: ENVIRONMENT=production, DEMO_MODE=true
# 6. Click Deploy
```

---

### Option C: Railway.app

**Free tier:** $5 credit/month (sufficient for a low-traffic RuView demo).

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Init and deploy
railway init
railway up

# Set environment variables
railway variables set ENVIRONMENT=production
railway variables set DEMO_MODE=true
railway variables set SECRET_KEY=your-secret
```

**railway.json**
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": { "builder": "DOCKERFILE", "dockerfilePath": "Dockerfile" },
  "deploy": {
    "startCommand": null,
    "healthcheckPath": "/health",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

---

### Option D: Self-host on a VPS (Oracle Cloud — always free)

Oracle Cloud offers **2 ARM VMs (4 OCPUs, 24 GB RAM total) permanently free** —
the best free tier for a persistent RuView server.

```bash
# 1. Sign up: https://cloud.oracle.com (requires credit card for verification only)
# 2. Create an ARM-based Ampere VM (Always Free tier)
# 3. SSH into it, then:

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Clone and run RuView
git clone https://github.com/ruvnet/RuView.git
cd RuView
docker compose up -d

# Open firewall port
sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

# Access from anywhere:
# http://<YOUR_OCI_IP>:8000
```

---

### Option E: GitHub Pages (frontend only) + Fly.io (backend)

Deploy the frontend as a static site (free, global CDN) and point it at your
Fly.io backend.

```bash
# In frontend/app.js — change WS_URL to point at cloud backend
const WS_URL = 'wss://my-ruview-app.fly.dev/ws/pose';

# Push frontend/ to gh-pages branch
git subtree push --prefix frontend origin gh-pages
# Site available at: https://<username>.github.io/<repo>
```

---

## Step 7 — Custom Application Examples

### Elder care / fall detection app
```python
# backend/alerts.py — extend the RuView server with alert logic
import asyncio, httpx

FALL_KEYPOINTS = {"right_knee", "left_knee", "right_hip", "left_hip"}
PHONE_NUMBER   = "+91XXXXXXXXXX"   # Twilio / Fast2SMS

async def check_for_fall(frame: dict):
    """Detect if a person's hip keypoints drop below knee keypoints (fall)."""
    for person in frame.get("persons", []):
        kps = {kp["name"]: kp for kp in person["keypoints"]}
        hip_y   = (kps["right_hip"]["y"] + kps["left_hip"]["y"]) / 2
        knee_y  = (kps["right_knee"]["y"] + kps["left_knee"]["y"]) / 2
        if hip_y > knee_y + 0.15 and person["vitals"]["activity"] != "lying":
            await send_alert(f"⚠️ Possible fall detected! Breathing: {person['vitals']['breathing_bpm']} BPM")

async def send_alert(message: str):
    # Use Fast2SMS free tier (India) or Twilio trial
    async with httpx.AsyncClient() as client:
        await client.post("https://www.fast2sms.com/dev/bulkV2",
            headers={"authorization": "YOUR_API_KEY"},
            json={"route": "q", "message": message, "numbers": PHONE_NUMBER})
```

### Smart office occupancy dashboard
```javascript
// frontend/occupancy.js — room occupancy heatmap (hourly)
const hourly = new Array(24).fill(0);

ws.onmessage = ({ data }) => {
  const frame = JSON.parse(data);
  const hour  = new Date().getHours();
  hourly[hour] = Math.max(hourly[hour], frame.occupancy_count);
  renderHeatmap(hourly);
};

function renderHeatmap(data) {
  // Render as a 24-bar horizontal bar chart via Chart.js
  chart.data.datasets[0].data = data;
  chart.update('none');
}
```

### Sleep quality tracker
```python
# backend/sleep.py — store overnight CSI events, classify sleep stages
import sqlite3, json, time

conn = sqlite3.connect("sleep.db")
conn.execute("""CREATE TABLE IF NOT EXISTS sessions (
  ts REAL, breathing REAL, heart_rate REAL, activity TEXT
)""")

async def record_vitals(frame: dict):
    for person in frame.get("persons", []):
        v = person["vitals"]
        conn.execute("INSERT INTO sessions VALUES (?,?,?,?)",
          (time.time(), v["breathing_bpm"], v["heart_rate_bpm"], v["activity"]))
    conn.commit()

def classify_sleep_stage(breathing_bpm: float, movement: bool) -> str:
    if breathing_bpm < 10 and not movement:  return "Deep sleep"
    if breathing_bpm < 14 and not movement:  return "Light sleep"
    if movement:                             return "REM / awake"
    return "Unknown"
```

---

## Step 8 — Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `development` | `production` enables auth + rate limiting |
| `DEMO_MODE` | `false` | `true` = simulated CSI data, no hardware needed |
| `SECRET_KEY` | (required in prod) | JWT signing key — use `openssl rand -hex 32` |
| `WORKERS` | `1` | Uvicorn worker count (set to 4 in production) |
| `PORT` | `8000` | HTTP server port |
| `LOG_LEVEL` | `info` | `debug` for verbose CSI frame logging |
| `MAX_PERSONS` | `4` | Max simultaneous tracked persons |
| `CALIBRATION_FRAMES` | `300` | Frames to collect during room calibration |

---

## Step 9 — Debugging & Common Issues

### WebSocket not connecting
```bash
# Check server is running and healthy
curl http://localhost:8000/health

# Test WebSocket with wscat
npm install -g wscat
wscat -c ws://localhost:8000/ws/pose

# Check CORS — in production behind a proxy, ensure WS upgrade headers pass through
```

### Docker build fails
```bash
# Clear Docker cache and rebuild
docker compose down -v
docker system prune -f
docker compose build --no-cache
docker compose up
```

### ESP32 nodes not connecting to server
```bash
# Verify nodes can reach server IP
ping 192.168.1.X   # from same network device

# Check node serial output for error codes
pio device monitor --baud 115200

# Common fix: nodes must be on 2.4 GHz, not 5 GHz network
```

### Pose estimation is noisy / jittery
```bash
# Trigger room calibration (clears baseline RF noise)
curl -X POST http://localhost:8000/api/v1/calibrate

# Wait 5 minutes for adaptive filtering to stabilize
# Ensure no large metallic objects (fridges, metal doors) near nodes
```

### Fly.io WebSocket drops
```toml
# In fly.toml — increase idle timeout for long-lived WS connections
[http_service]
  idle_timeout = 3600   # 1 hour in seconds
```

---

## Step 10 — Monitoring Live Data

### Local
```bash
docker compose logs -f wifi-densepose          # Raw server logs
# Open http://localhost:8000                   # Observatory UI (3D skeleton + signal tab)
# Open http://localhost:9880                   # Point cloud viewer (if Rust v2 running)
```

### Production (Fly.io)
```bash
fly logs --app my-ruview-app                   # Tail live logs
fly status --app my-ruview-app                 # VM health
fly ssh console --app my-ruview-app            # SSH into VM
```

### Health check endpoint
```bash
curl https://my-ruview-app.fly.dev/health
# {"status":"ok","demo_mode":true,"connected_nodes":0,"ws_clients":1}
```

---

## Checklist: Before Going Live

- [ ] `DEMO_MODE=false` (if using real hardware)
- [ ] `ENVIRONMENT=production`
- [ ] `SECRET_KEY` set to a random 32-byte hex string
- [ ] Room calibration triggered after sensor placement
- [ ] WebSocket client uses `wss://` (TLS) in production, not `ws://`
- [ ] CORS origins restricted to your frontend domain
- [ ] Fly.io / Render health check passing at `/health`
- [ ] Auto-reconnect logic in frontend WebSocket client
- [ ] Privacy disclosure if deploying in shared spaces (WiFi sensing is passive but should be disclosed)

---

## Resources

| Resource | URL |
|----------|-----|
| GitHub repo | https://github.com/ruvnet/RuView |
| Build guide | https://github.com/ruvnet/RuView/blob/main/docs/build-guide.md |
| User guide | https://github.com/ruvnet/RuView/blob/main/docs/user-guide.md |
| DeepWiki docs | https://deepwiki.com/ruvnet/RuView |
| rvcsi crates (Rust) | https://crates.io (search: rvcsi) |
| @ruv/rvcsi (npm) | https://www.npmjs.com/package/@ruv/rvcsi |
| Fly.io free tier | https://fly.io/docs/about/pricing/ |
| Oracle Always Free | https://www.oracle.com/cloud/free/ |
| Fast2SMS (India) | https://www.fast2sms.com (free 200 SMS/day) |
