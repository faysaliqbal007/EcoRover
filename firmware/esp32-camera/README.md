# EcoRover ESP32-CAM Streaming Node

## Subsystem Overview
The camera subsystem operates as an independent, wireless video node mounted on the dual-axis (pan/tilt) servo turret. Rather than sharing resources with motor PWM, sensor polling, and web server routines on the main ESP32-S3, this dedicated ESP32-CAM module handles video capture and low-latency HTTP MJPEG streaming.

## Network Configuration
- **Network Mode**: Wi-Fi Station (`WIFI_STA`)
- **Target SSID**: `EcoRover` (Broadcast by the main ESP32-S3)
- **Wi-Fi Password**: `12345678`
- **Assigned Static IP**: `192.168.4.200`
- **Subnet Mask**: `255.255.255.0`
- **Default Gateway**: `192.168.4.1`

## API Endpoints
- **Live MJPEG Stream**: `http://192.168.4.200/stream`
- **Still Snapshot**: `http://192.168.4.200/snapshot`

## Hardware Pin Connections
| Function | ESP32-CAM GPIO | Notes |
|:---|:---:|:---|
| **PWDN** | GPIO32 | Power down control |
| **RESET** | -1 | Software reset |
| **XCLK** | GPIO0 | External clock 20 MHz |
| **SIOD** | GPIO26 | I2C SCCB Data |
| **SIOC** | GPIO27 | I2C SCCB Clock |
| **Y9 (D7)** | GPIO35 | Video Data Bit 7 |
| **Y8 (D6)** | GPIO34 | Video Data Bit 6 |
| **Y7 (D5)** | GPIO39 | Video Data Bit 5 |
| **Y6 (D4)** | GPIO36 | Video Data Bit 4 |
| **Y5 (D3)** | GPIO21 | Video Data Bit 3 |
| **Y4 (D2)** | GPIO19 | Video Data Bit 2 |
| **Y3 (D1)** | GPIO18 | Video Data Bit 1 |
| **Y2 (D0)** | GPIO5 | Video Data Bit 0 |
| **VSYNC** | GPIO25 | Vertical synchronization |
| **HREF** | GPIO23 | Horizontal reference |
| **PCLK** | GPIO22 | Pixel clock |

## Flashing Instructions (FTDI Programmer)
1. Connect FTDI `TX` -> ESP32-CAM `U0R` (GPIO3).
2. Connect FTDI `RX` -> ESP32-CAM `U0T` (GPIO1).
3. Connect FTDI `VCC (5V)` -> ESP32-CAM `5V`.
4. Connect FTDI `GND` -> ESP32-CAM `GND`.
5. Connect ESP32-CAM `IO0` to `GND` (enables flashing bootloader).
6. In Arduino IDE, select board **AI Thinker ESP32-CAM**.
7. Partition Scheme: **Huge APP (3MB No OTA/1MB SPIFFS)**.
8. Press ESP32-CAM RST button, then click **Upload**.
9. Once uploaded, remove the `IO0` to `GND` jumper and press RST again.
