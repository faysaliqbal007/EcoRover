# EcoRover Circuit & Wiring Architecture

## Power Rail Separation & Electrical Safety
The EcoRover electrical system employs strict physical separation between high-current inductive motor rails and noise-sensitive 3.3V/5V logic rails:

```
[12V Battery Pack]
      |
      +-------------------------> [L298N Motor Drivers 12V VMS] ---> 4x TT Motors
      |
      +---> [LM2596 Buck (5.0V)]
                  |
                  +-------------> ESP32-S3 (5V / VIN pin)
                  +-------------> ESP32-CAM (5V pin)
                  +-------------> SG90 Servos (Pan & Tilt VCC)
                  +-------------> HC-SR04 Sensors (VCC)
                  +-------------> Active Buzzer (VCC)

[COMMON GROUND BUS]
Connects: Battery (-), Buck GND, ESP32-S3 GND, ESP32-CAM GND, L298N GNDs, Sensor GNDs.
```

> [!CAUTION]
> **Never connect the 12V motor supply directly to any ESP32 pin!** Always verify the buck converter output measures exactly 5.0V with a multimeter before plugging in the ESP32 boards.

---

## Logic Level Shifting (5V to 3.3V)
HC-SR04 Ultrasonic sensors run at 5V and output 5V logic on their `ECHO` pins. The ESP32-S3 GPIO pins are rated for 3.3V maximum. A voltage divider is installed on both Front (`GPIO7`) and Rear (`GPIO11`) echo lines:
```
ECHO (5V) ----[ 1 kΩ ]----+----> ESP32 GPIO (3.33V)
                         |
                       [ 2 kΩ ]
                         |
                        GND
```
$$V_{out} = 5.0\text{V} \times \frac{2\text{k}\Omega}{1\text{k}\Omega + 2\text{k}\Omega} = 3.33\text{V}$$
