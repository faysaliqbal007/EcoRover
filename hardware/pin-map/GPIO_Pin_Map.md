# EcoRover Hardware GPIO Pin Map

## Main Controller: ESP32-S3 N16R8

### 1. Sensors & Peripherals
| Component | ESP32-S3 GPIO | Function / Signal Type | Voltage Level | Notes |
|:---|:---:|:---|:---:|:---|
| **LDR Light Sensor** | GPIO4 | ADC1 Analog Input | 0 - 3.3V | 10kΩ voltage divider (Dark <= 100, Bright >= 250) |
| **Headlights** | GPIO5 | Digital Output | 3.3V | Drives front/rear LED headlights |
| **Front Ultrasonic TRIG** | GPIO6 | Digital Output | 3.3V | 10µs trigger pulse |
| **Front Ultrasonic ECHO** | GPIO7 | Digital Input | 3.3V | 5V ECHO reduced via 1kΩ / 2kΩ voltage divider |
| **OLED Display SDA** | GPIO8 | I2C Data | 3.3V | SH1106 128x64 OLED display |
| **OLED Display SCL** | GPIO9 | I2C Clock | 3.3V | SH1106 128x64 OLED display |
| **Rear Ultrasonic TRIG** | GPIO10 | Digital Output | 3.3V | 10µs trigger pulse |
| **Rear Ultrasonic ECHO** | GPIO11 | Digital Input | 3.3V | 5V ECHO reduced via 1kΩ / 2kΩ voltage divider |
| **Pan Servo (Horizontal)** | GPIO12 | LEDC PWM (CH4, 50Hz) | 3.3V logic / 5V pwr | 0° - 180° range (14-bit resolution) |
| **Tilt Servo (Vertical)** | GPIO13 | LEDC PWM (CH5, 50Hz) | 3.3V logic / 5V pwr | 0° - 180° range (14-bit resolution) |
| **Active Buzzer** | GPIO14 | Digital Output | 3.3V | Active HIGH audible alert |
| **Right IR Obstacle Sensor** | GPIO15 | Digital Input | 3.3V | `INPUT_PULLUP`; LOW indicates obstacle |
| **Built-in RGB LED** | GPIO48 | Addressable WS2812 | 3.3V | On-board status and danger warning light |

---

### 2. Motor Driver Connections (Dual L298N H-Bridges)
| Motor Location | IN1 (Direction) | IN2 (Direction) | Enable / PWM Pin | LEDC Channel | Frequency | Resolution |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **Front Left (FL)** | GPIO17 | GPIO16 | GPIO39 | CH0 | 1500 Hz | 8-bit (0-255) |
| **Rear Left (RL)** | GPIO18 | GPIO21 | GPIO38 | CH1 | 1500 Hz | 8-bit (0-255) |
| **Front Right (FR)** | GPIO1 | GPIO2 | GPIO42 | CH2 | 1500 Hz | 8-bit (0-255) |
| **Rear Right (RR)** | GPIO41 | GPIO40 | GPIO47 | CH3 | 1500 Hz | 8-bit (0-255) |

> [!IMPORTANT]
> **Verified Correction**: The Rear Right motor direction uses **GPIO40** for `RR_IN2`. Older experimental pin allocations must not be used.

---

### 3. ESP32-CAM Wireless Node GPIO Map
| Signal | Pin | Signal | Pin |
|:---|:---:|:---|:---:|
| **PWDN** | GPIO32 | **RESET** | -1 (Unused) |
| **XCLK** | GPIO0 | **SIOD / SIOC** | GPIO26 / GPIO27 |
| **D7 / D6 / D5 / D4** | GPIO35 / 34 / 39 / 36 | **D3 / D2 / D1 / D0** | GPIO21 / 19 / 18 / 5 |
| **VSYNC / HREF / PCLK** | GPIO25 / 23 / 22 | **Power & GND** | 5V Regulated & Common GND |
