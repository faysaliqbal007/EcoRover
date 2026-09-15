# Main Controller Setup (ESP32-S3)

## Prerequisites
1. **Arduino IDE 2.x** or **VS Code with PlatformIO**.
2. **ESP32 Board Package**: Version `2.0.14` or later by Espressif Systems.
3. **Libraries**:
   - `U8g2` by olikraus (Install via Library Manager).

## Step-by-Step Flashing Procedure
1. Open `firmware/main-controller/EcoRover_V6.ino` in Arduino IDE.
2. Ensure `dashboard_gz.h` is located in the same directory.
3. Connect the ESP32-S3 to your computer via USB (use the **USB CDC** or **UART** port).
4. Select the following settings under the **Tools** menu:
   - **Board**: `ESP32S3 Dev Module`
   - **Upload Speed**: `921600`
   - **USB Mode**: `Hardware CDC and JTAG`
   - **USB CDC On Boot**: `Enabled`
   - **Flash Mode**: `QIO 80MHz`
   - **Flash Size**: `16MB (128Mb)`
   - **Partition Scheme**: `16M Flash (3MB APP/9.9MB FATFS)` or `Default 4MB with spiffs`
   - **PSRAM**: `OPI PSRAM`
5. Click **Verify** to compile.
6. Click **Upload** to flash the firmware.
7. Open Serial Monitor at **115200 baud** to confirm:
   - AP initialized at `192.168.4.1`
   - UDP socket listening on port `2055`
   - I2C OLED initialized
