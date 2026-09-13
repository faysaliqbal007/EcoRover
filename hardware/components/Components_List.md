# EcoRover Hardware Components List (Bill of Materials)

## 1. Computing & Processing
| Component | Specification | Quantity | Primary Purpose |
|:---|:---|:---:|:---|
| **Main Microcontroller** | ESP32-S3-WROOM-1 N16R8 (16MB Flash, 8MB OPI PSRAM) | 1 | Locomotion, kinematics, sensor fusion, AP server, UDP receiver |
| **Camera Controller** | AI-Thinker ESP32-CAM Board | 1 | Dedicated video streaming node |
| **Camera Sensor** | GC2145 / OV2640 2MP Camera Sensor | 1 | 640x480 VGA live MJPEG video capture |

---

## 2. Locomotion & Drivetrain
| Component | Specification | Quantity | Primary Purpose |
|:---|:---|:---:|:---|
| **Motor Drivers** | L298N Dual H-Bridge Motor Driver Module | 2 | Left-side and Right-side dual DC motor control with PWM speed regulation |
| **Motors** | TT DC Geared Motors (1:48 gear ratio, 3V-6V / 12V rated) | 4 | Drive wheels (Front-Left, Rear-Left, Front-Right, Rear-Right) |
| **Mecanum Wheels** | 60mm / 80mm Omnidirectional Mecanum Wheels (2L + 2R) | 4 | Enables 360° holonomic locomotion (strafe, diagonal, spin, curves) |
| **Turret Servos** | SG90 / MG90S Micro Servo Motors (180° rotation) | 2 | Pan (horizontal) and Tilt (vertical) camera bracket movement |

---

## 3. Sensors & Display
| Component | Specification | Quantity | Primary Purpose |
|:---|:---|:---:|:---|
| **Ultrasonic Sensors** | HC-SR04 Ultrasonic Distance Sensor | 2 | Front obstacle avoidance (30cm) and Rear obstacle detection (25cm) |
| **Infrared Sensor** | Digital IR Obstacle Sensor Module (Active LOW) | 1 | Right-side collision detection |
| **Light Sensor** | 5mm LDR (Light Dependent Resistor) Photocell | 1 | Ambient illumination measurement for automatic headlights |
| **OLED Display** | SH1106 / SSD1306 128x64 0.96" or 1.3" I2C Display | 1 | Real-time IP address, mode, speed, and sensor telemetry display |

---

## 4. Power & Electrical Distribution
| Component | Specification | Quantity | Primary Purpose |
|:---|:---|:---:|:---|
| **Main Battery** | 2200 mAh 11.1V - 12.6V 3S Lithium Battery Pack | 1 | High-current power for 4 DC motors via L298N drivers |
| **DC-DC Buck Converter** | LM2596 / XL4015 Step-Down Regulator (12V to 5.0V / 3A) | 1 | Regulated clean 5V supply for ESP32-S3, ESP32-CAM, servos, and sensors |
| **Power Switch** | Heavy-duty SPST / Rocker Switch | 1 | Main battery isolation switch |

---

## 5. Protection Components & Passives
| Component | Specification | Quantity | Primary Purpose |
|:---|:---|:---:|:---|
| **ECHO Resistor (Upper)** | 1.0 kΩ, 1/4W Resistor | 2 | Upper leg of 5V to 3.3V voltage divider for Front & Rear HC-SR04 ECHO |
| **ECHO Resistor (Lower)** | 2.0 kΩ, 1/4W Resistor | 2 | Lower leg of 5V to 3.3V voltage divider for Front & Rear HC-SR04 ECHO |
| **LDR Divider Resistor** | 10.0 kΩ, 1/4W Resistor | 1 | Pull-down resistor for LDR analog voltage divider on GPIO4 |
| **LED Current Limiters** | 220 Ω, 1/4W Resistor | 2+ | Current limiting for front/rear headlight LEDs on GPIO5 |
| **Headlight LEDs** | 5mm High-brightness White / Warm LEDs | 2+ | Night illumination and obstacle headlights |
| **Active Buzzer** | 5V Active Piezo Buzzer | 1 | Audible obstacle warning and command confirmation beeps |
