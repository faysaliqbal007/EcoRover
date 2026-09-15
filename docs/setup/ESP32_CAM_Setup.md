# ESP32-CAM Setup Guide

## Hardware Required
- AI-Thinker ESP32-CAM module with GC2145 or OV2640 sensor
- FTDI USB-to-TTL programmer module (configured for 5V VCC)
- 4x Female-to-Female jumper wires + 1x short jumper wire

## Flashing Wiring Table
| FTDI Programmer Pin | ESP32-CAM Pin | Purpose |
|:---:|:---:|:---|
| **VCC (5V)** | **5V** | Power (Do not use 3.3V pin on ESP32-CAM) |
| **GND** | **GND** | Ground reference |
| **TX** | **U0R (GPIO3)** | UART Receive |
| **RX** | **U0T (GPIO1)** | UART Transmit |
| **Jumper Wire** | **IO0 to GND** | Puts ESP32 into bootloader flashing mode |

## Arduino IDE Configuration
1. Open `firmware/esp32-camera/EcoRover_Camera.ino`.
2. Under **Tools**:
   - **Board**: `AI Thinker ESP32-CAM`
   - **CPU Frequency**: `240MHz`
   - **Flash Frequency**: `80MHz`
   - **Flash Mode**: `QIO`
   - **Partition Scheme**: `Huge APP (3MB No OTA/1MB SPIFFS)`
3. Connect FTDI to PC, press the **RST** button on the bottom of the ESP32-CAM, and click **Upload**.
4. Once completed, **disconnect the IO0 to GND wire** and press RST once more.
5. In Serial Monitor (115200 baud), verify:
   ```
   [CAM] Connecting to Wi-Fi SSID 'EcoRover'...
   [CAM] Connected to EcoRover Network!
   [CAM] Node IP Address: 192.168.4.200
   [CAM] Stream ready at: http://192.168.4.200/stream
   ```
