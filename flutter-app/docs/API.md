# EcoRover V6 API Contract

All endpoints are HTTP GET. The controller base URL defaults to `http://192.168.4.1`.

## General

| Endpoint | Description |
|----------|-------------|
| `GET /api/status` | Returns JSON with full rover state. Also acts as heartbeat. |
| `GET /api/config` | Returns controller IP, camera stream URL, and UDP port. |
| `GET /api/idle` | Stops all drive; switches mode to IDLE. |
| `GET /api/emergency` | Emergency stop: IDLE mode, all accessories off. |

### /api/status Response

```json
{
  "mode": "IDLE",
  "drive": "STOP",
  "front": 175.4,
  "rear": 45.2,
  "rightObstacle": false,
  "obstacle": false,
  "allBlocked": false,
  "ldr": 280,
  "headlight": false,
  "headlightManual": false,
  "headlightAuto": false,
  "accessoriesLocked": false,
  "buzzer": false,
  "rgb": false,
  "rgbColor": "BLUE",
  "pan": 90,
  "tilt": 90,
  "manualSpeed": 50,
  "autoSpeed": 50,
  "motionSensitivity": 50,
  "phoneCalibrated": false,
  "clients": 1
}
```

## Manual Drive (Latched)

All drive commands are **latched** — the rover continues until a new command or STOP is sent.

| Endpoint | Direction |
|----------|-----------|
| `GET /api/manual/forward` | Forward |
| `GET /api/manual/backward` | Backward |
| `GET /api/manual/left` | Curve left (forward-biased) |
| `GET /api/manual/right` | Curve right (forward-biased) |
| `GET /api/manual/strafe-left` | FAST LEFT — mecanum lateral |
| `GET /api/manual/strafe-right` | FAST RIGHT — mecanum lateral |
| `GET /api/manual/spin-left` | Spin in place left |
| `GET /api/manual/spin-right` | Spin in place right |
| `GET /api/manual/diag-fl` | Diagonal forward-left |
| `GET /api/manual/diag-fr` | Diagonal forward-right |
| `GET /api/manual/diag-bl` | Diagonal backward-left |
| `GET /api/manual/diag-br` | Diagonal backward-right |
| `GET /api/manual/stop` | Stop |
| `GET /api/manual/speed?percent=<0-100>` | Set manual speed |

## Autonomous

| Endpoint | Description |
|----------|-------------|
| `GET /api/auto/start` | Start autonomous obstacle-avoidance navigation |
| `GET /api/auto/stop` | Stop autonomous mode |
| `GET /api/auto/speed?percent=<0-100>` | Set auto speed |

## Motion Control (Phone Tilt)

| Endpoint | Description |
|----------|-------------|
| `GET /api/motion/start` | Start motion mode (begin calibration) |
| `GET /api/motion/stop` | Stop motion mode |
| `GET /api/motion/sensitivity?percent=<10-100>` | Set tilt sensitivity |

### UDP Motion Packets

- **Destination:** `192.168.4.1:2055`
- **Protocol:** UDP
- **Format:** `x,y,z` — plain UTF-8, no JSON, no spaces
- **Rate:** ~33 Hz (30ms interval)
- **Calibration:** First 50 packets are used for zero calibration

**Axis Convention:**
- Y negative → forward
- Y positive → backward
- X negative → strafe left
- X positive → strafe right

## Servo

| Endpoint | Range | Default |
|----------|-------|---------|
| `GET /api/pan?angle=<0-180>` | 0°–180° | 90° |
| `GET /api/tilt?angle=<0-180>` | 0°–180° | 90° |

## RGB

| Endpoint | Description |
|----------|-------------|
| `GET /api/rgb/color?name=red` | Select red |
| `GET /api/rgb/color?name=green` | Select green |
| `GET /api/rgb/color?name=blue` | Select blue |
| `GET /api/rgb/color?name=yellow` | Select yellow |
| `GET /api/rgb/color?name=white` | Select white |
| `GET /api/rgb/on` | Turn RGB on |
| `GET /api/rgb/off` | Turn RGB off (obstacle warning auto resumes) |

## Buzzer

| Endpoint | Description |
|----------|-------------|
| `GET /api/buzzer/on` | Force buzzer ON |
| `GET /api/buzzer/off` | Return to AUTO (obstacle-triggered) |

## Headlight

| Endpoint | Description |
|----------|-------------|
| `GET /api/headlight/on` | Force headlight ON |
| `GET /api/headlight/off` | Return to AUTO (LDR-controlled) |

## Camera

| URL | Description |
|-----|-------------|
| `http://192.168.4.200/stream` | MJPEG stream |

> **Note:** The ESP32-CAM firmware is **not modified**. Photo capture and video recording happen on Android by parsing the MJPEG stream.

## Drive State → Status String Mapping

| V6 Drive State | `/api/status` `drive` value |
|---------------|---------------------------|
| FORWARD | `FORWARD` |
| BACKWARD | `BACKWARD` |
| CURVE_LEFT | `LEFT` |
| CURVE_RIGHT | `RIGHT` |
| STRAFE_LEFT | `STRAFE_LEFT` |
| STRAFE_RIGHT | `STRAFE_RIGHT` |
| SPIN_LEFT | `SPIN_LEFT` |
| SPIN_RIGHT | `SPIN_RIGHT` |
| DIAG_FL | `DIAG_FL` |
| DIAG_FR | `DIAG_FR` |
| DIAG_BL | `DIAG_BL` |
| DIAG_BR | `DIAG_BR` |
| STOP | `STOP` |
