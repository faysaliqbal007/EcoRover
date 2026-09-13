# EcoRover Web Control Dashboard

## Overview
The web dashboard provides a complete, zero-dependency browser control console accessible over the local EcoRover Wi-Fi network at `http://192.168.4.1`. It can be run directly from any desktop or mobile browser without requiring app installation.

## Files
- `dashboard.html` : Uncompressed, readable HTML5/CSS3 user interface.
- `dashboard.js` : Vanilla JavaScript logic handling real-time telemetry polling, latched D-pad driving, pan/tilt servo sliders, camera embedding, and accessory control.
- `dashboard_gz.h` : Pre-compressed GZIP byte array header included in the ESP32-S3 firmware. Storing the dashboard as compressed binary prevents C++ string escaping errors and conserves Flash/RAM.

## How to Re-generate `dashboard_gz.h`
If you modify `dashboard.html` or `dashboard.js`:
1. Inline `dashboard.js` and CSS into a single standalone `dashboard.html` file.
2. Compress `dashboard.html` using gzip:
   ```bash
   gzip -9 -c dashboard.html > dashboard.html.gz
   ```
3. Convert the gzip file to a C-style hex array:
   ```bash
   xxd -i dashboard.html.gz > dashboard_gz.h
   ```
4. Copy `dashboard_gz.h` into `firmware/main-controller/`.
