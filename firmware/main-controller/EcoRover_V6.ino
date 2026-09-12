/*
   ============================================================
                    ECOROVER MASTER V6
   ============================================================

   ESP32-S3 Main Controller
   Dashboard : http://192.168.4.1
   Camera    : http://192.168.4.200/stream

   IMPORTANT:
   - ESP32-CAM firmware stays unchanged.
   - Dashboard is stored as GZIP BYTES in dashboard_gz.h.
   - JavaScript is never present as C++ source, so the recurring
     "function does not name a type" error cannot be caused by
     the dashboard anymore.
   - No ESP32Servo library.
   - Explicit LEDC channels are preserved.
   - Current verified motor GPIO mapping is preserved.
*/

#include <WiFi.h>
#include <WebServer.h>
#include <WiFiUdp.h>
#include <Wire.h>
#include <U8g2lib.h>
#include <esp32-hal-rgb-led.h>
#include "dashboard_gz.h"

// ============================================================
// WIFI
// ============================================================

const char* WIFI_SSID = "EcoRover";
const char* WIFI_PASSWORD = "12345678";

IPAddress AP_IP(192, 168, 4, 1);
IPAddress AP_GATEWAY(192, 168, 4, 1);
IPAddress AP_SUBNET(255, 255, 255, 0);

WebServer server(80);
WiFiUDP udp;

const uint16_t UDP_PORT = 2055;
char udpBuffer[255];

// ============================================================
// GENERAL GPIO
// ============================================================

#define LDR_PIN         4
#define HEADLIGHT_PIN   5
#define FRONT_TRIG      6
#define FRONT_ECHO      7
#define SDA_PIN         8
#define SCL_PIN         9
#define REAR_TRIG       10
#define REAR_ECHO       11
#define PAN_SERVO_PIN   12
#define TILT_SERVO_PIN  13
#define BUZZER_PIN      14
#define RIGHT_IR_PIN    15
#define RGB_PIN         48

// ============================================================
// VERIFIED MOTOR GPIO
// ============================================================

#define FL_IN1 17
#define FL_IN2 16
#define FL_EN  39

#define RL_IN1 18
#define RL_IN2 21
#define RL_EN  38

#define FR_IN1 1
#define FR_IN2 2
#define FR_EN  42

#define RR_IN1 41
#define RR_IN2 40
#define RR_EN  47

const uint8_t MOTOR_IN1[4] = {FL_IN1, RL_IN1, FR_IN1, RR_IN1};
const uint8_t MOTOR_IN2[4] = {FL_IN2, RL_IN2, FR_IN2, RR_IN2};
const uint8_t MOTOR_EN[4]  = {FL_EN,  RL_EN,  FR_EN,  RR_EN};

// ============================================================
// PWM
// ============================================================

#define CH_FL    0
#define CH_RL    1
#define CH_FR    2
#define CH_RR    3
#define CH_PAN   4
#define CH_TILT  5

const uint32_t MOTOR_FREQ = 1500;
const uint8_t MOTOR_RESOLUTION = 8;

const uint32_t SERVO_FREQ = 50;
const uint8_t SERVO_RESOLUTION = 14;

// ============================================================
// OLED
// ============================================================

U8G2_SH1106_128X64_NONAME_F_HW_I2C oled(
  U8G2_R0,
  U8X8_PIN_NONE
);

// ============================================================
// MODE
// ============================================================

enum RoverMode {
  MODE_IDLE,
  MODE_MANUAL,
  MODE_AUTONOMOUS,
  MODE_MOTION
};

RoverMode roverMode = MODE_IDLE;

// ============================================================
// DRIVE STATES
// ============================================================

enum DriveState {
  DRIVE_STOP,
  DRIVE_FORWARD,
  DRIVE_BACKWARD,
  DRIVE_CURVE_LEFT,
  DRIVE_CURVE_RIGHT,
  DRIVE_STRAFE_LEFT,
  DRIVE_STRAFE_RIGHT,
  DRIVE_SPIN_LEFT,
  DRIVE_SPIN_RIGHT,
  DRIVE_DIAG_FL,
  DRIVE_DIAG_FR,
  DRIVE_DIAG_BL,
  DRIVE_DIAG_BR
};

DriveState driveState = DRIVE_STOP;

// ============================================================
// SPEEDS
// ============================================================

int manualSpeedPercent = 50;
int autoSpeedPercent = 50;
int motionSpeedPercent = 50;

const unsigned long MOTOR_KICK_MS = 90;

// ============================================================
// DASHBOARD HEARTBEAT
// ============================================================

// Manual command stays latched until another command/STOP/mode.
// The status request is the safety heartbeat.

unsigned long lastDashboardHeartbeat = 0;
const unsigned long DASHBOARD_TIMEOUT = 4000;

// ============================================================
// SENSOR VALUES
// ============================================================

float frontDistance = -1.0f;
float rearDistance = -1.0f;

bool frontObstacle = false;
bool rearObstacle = false;
bool rightObstacle = false;
bool anyObstacle = false;

int ldrValue = 0;

const float FRONT_BLOCK_DISTANCE = 30.0f;
const float REAR_BLOCK_DISTANCE  = 25.0f;
const float LEFT_SCAN_DISTANCE   = 30.0f;

// ============================================================
// ACCESSORIES
// ============================================================

bool headlightEnabled = false;          // Manual force-ON request
bool automaticHeadlightOn = false;      // LDR result
bool physicalHeadlightOn = false;       // Actual GPIO5 state

const int DARK_ON_THRESHOLD = 100;
const int BRIGHT_OFF_THRESHOLD = 250;
const unsigned long DARK_DELAY = 3000;
const unsigned long BRIGHT_DELAY = 1000;
unsigned long darkStarted = 0;
unsigned long brightStarted = 0;

const bool BUZZER_ACTIVE_HIGH = true;
bool userBuzzerEnabled = false;

bool userRgbEnabled = false;
uint8_t userRgbR = 0;
uint8_t userRgbG = 0;
uint8_t userRgbB = 255;
String userRgbName = "BLUE";

bool warningActiveLast = false;
bool warningBlink = false;
unsigned long lastWarningToggle = 0;
const unsigned long WARNING_INTERVAL = 250;

// ============================================================
// SERVO
// ============================================================

int panAngle = 90;
int tiltAngle = 90;

// ============================================================
// AUTONOMOUS
// ============================================================

const unsigned long TURN_90_TIME = 480;
const unsigned long BACKUP_TIME = 350;
const unsigned long AUTO_DECISION_INTERVAL = 180;

unsigned long lastAutoDecision = 0;
bool autoAllBlocked = false;

// ============================================================
// PHONE MOTION / HYPERIMU
// ============================================================

float phoneX = 0.0f;
float phoneY = 0.0f;
float phoneZ = 0.0f;

float phoneZeroX = 0.0f;
float phoneZeroY = 0.0f;
float phoneSumX = 0.0f;
float phoneSumY = 0.0f;

int phoneCalibrationSamples = 0;
bool phoneCalibrated = false;

unsigned long lastPhonePacket = 0;
const unsigned long PHONE_TIMEOUT = 700;

int motionSensitivityPercent = 50;
float phoneTiltThreshold = 2.5f;

// ============================================================
// PERIODIC TIMERS
// ============================================================

unsigned long lastSensorUpdate = 0;
unsigned long lastOLEDUpdate = 0;

const unsigned long SENSOR_INTERVAL = 220;
const unsigned long OLED_INTERVAL = 500;

// ============================================================
// MODE / DRIVE NAMES
// ============================================================

const char* modeName() {
  switch (roverMode) {
    case MODE_MANUAL:     return "MANUAL";
    case MODE_AUTONOMOUS: return "AUTONOMOUS";
    case MODE_MOTION:     return "MOTION";
    default:              return "IDLE";
  }
}

const char* driveName() {
  switch (driveState) {
    case DRIVE_FORWARD:      return "FORWARD";
    case DRIVE_BACKWARD:     return "BACKWARD";
    case DRIVE_CURVE_LEFT:   return "LEFT";
    case DRIVE_CURVE_RIGHT:  return "RIGHT";
    case DRIVE_STRAFE_LEFT:  return "STRAFE_LEFT";
    case DRIVE_STRAFE_RIGHT: return "STRAFE_RIGHT";
    case DRIVE_SPIN_LEFT:    return "SPIN_LEFT";
    case DRIVE_SPIN_RIGHT:   return "SPIN_RIGHT";
    case DRIVE_DIAG_FL:      return "DIAG_FL";
    case DRIVE_DIAG_FR:      return "DIAG_FR";
    case DRIVE_DIAG_BL:      return "DIAG_BL";
    case DRIVE_DIAG_BR:      return "DIAG_BR";
    default:                 return "STOP";
  }
}

// ============================================================
// SPEED
// ============================================================

int percentToPWM(int percent) {
  percent = constrain(percent, 0, 100);
  if (percent == 0) return 0;

  // UI remains 0-100%, usable motor PWM maps to 125-255.
  return map(percent, 1, 100, 125, 255);
}

int activeMotorPWM() {
  if (roverMode == MODE_AUTONOMOUS) return percentToPWM(autoSpeedPercent);
  if (roverMode == MODE_MOTION) return percentToPWM(motionSpeedPercent);
  return percentToPWM(manualSpeedPercent);
}

// ============================================================
// BUZZER
// ============================================================

void buzzerOn() {
  digitalWrite(BUZZER_PIN, BUZZER_ACTIVE_HIGH ? HIGH : LOW);
}

void buzzerOff() {
  digitalWrite(BUZZER_PIN, BUZZER_ACTIVE_HIGH ? LOW : HIGH);
}

// ============================================================
// RGB
// ============================================================

void setRGB(uint8_t r, uint8_t g, uint8_t b) {
  rgbLedWrite(RGB_PIN, r, g, b);
}

void rgbOff()    { setRGB(0, 0, 0); }
void rgbBlue()   { setRGB(0, 0, 150); }
void rgbYellow() { setRGB(180, 140, 0); }

void startupRGB() {
  for (int i = 0; i < 3; i++) {
    rgbBlue();
    delay(180);
    rgbOff();
    delay(130);
  }
}

void chooseRGBColor(String color) {
  color.toUpperCase();

  if (color == "RED") {
    userRgbR = 255; userRgbG = 0; userRgbB = 0;
  } else if (color == "GREEN") {
    userRgbR = 0; userRgbG = 255; userRgbB = 0;
  } else if (color == "BLUE") {
    userRgbR = 0; userRgbG = 0; userRgbB = 255;
  } else if (color == "YELLOW") {
    userRgbR = 255; userRgbG = 180; userRgbB = 0;
  } else if (color == "WHITE") {
    userRgbR = 255; userRgbG = 255; userRgbB = 255;
  } else {
    return;
  }

  userRgbName = color;
  userRgbEnabled = true;
}

void setHeadlight(bool enabled) {
  // Outside Auto/Motion this is a manual force-ON switch.
  // OFF means LDR automatic control remains active.
  headlightEnabled = enabled;
}

bool automaticDriveMode() {
  return roverMode == MODE_AUTONOMOUS || roverMode == MODE_MOTION;
}

void updateAutomaticHeadlight() {
  // Dark = low ADC in the verified LDR divider.
  if (ldrValue <= DARK_ON_THRESHOLD) {
    brightStarted = 0;
    if (darkStarted == 0) darkStarted = millis();
    if (!automaticHeadlightOn && millis() - darkStarted >= DARK_DELAY) {
      automaticHeadlightOn = true;
    }
    return;
  }

  if (ldrValue >= BRIGHT_OFF_THRESHOLD) {
    darkStarted = 0;
    if (brightStarted == 0) brightStarted = millis();
    if (automaticHeadlightOn && millis() - brightStarted >= BRIGHT_DELAY) {
      automaticHeadlightOn = false;
    }
    return;
  }

  // Hysteresis zone: keep previous state.
  darkStarted = 0;
  brightStarted = 0;
}

void updateHeadlightOutput() {
  bool output;

  if (automaticDriveMode()) {
    // Autonomous/Motion ignore any saved manual headlight value.
    output = automaticHeadlightOn;
  } else {
    // Manual ON forces light ON. Manual OFF returns to LDR automatic.
    output = headlightEnabled ? true : automaticHeadlightOn;
  }

  physicalHeadlightOn = output;
  digitalWrite(HEADLIGHT_PIN, output ? HIGH : LOW);
}

// ============================================================
// ACCESSORY PRIORITY / MODE ISOLATION
// ============================================================

void updateAccessoryOutputs() {
  bool warningRequired = anyObstacle || autoAllBlocked;

  if (warningRequired) {
    if (!warningActiveLast) {
      warningActiveLast = true;
      warningBlink = true;
      lastWarningToggle = millis();
    }

    if (millis() - lastWarningToggle >= WARNING_INTERVAL) {
      lastWarningToggle = millis();
      warningBlink = !warningBlink;
    }
  } else {
    warningActiveLast = false;
    warningBlink = false;
  }

  bool warningPhaseOn = warningRequired && warningBlink;

  if (automaticDriveMode()) {
    // Auto/Motion own the accessories. Saved manual values are ignored.
    if (warningPhaseOn) rgbYellow();
    else rgbOff();

    if (warningPhaseOn) buzzerOn();
    else buzzerOff();
    return;
  }

  // IDLE/MANUAL: each accessory can be manually overridden.
  // If its manual switch is OFF, automatic obstacle warning still works.
  if (userRgbEnabled) {
    setRGB(userRgbR, userRgbG, userRgbB);
  } else if (warningPhaseOn) {
    rgbYellow();
  } else {
    rgbOff();
  }

  if (userBuzzerEnabled) {
    buzzerOn();
  } else if (warningPhaseOn) {
    buzzerOn();
  } else {
    buzzerOff();
  }
}

// ============================================================
// SERVO
// ============================================================

uint32_t servoDuty(int angle) {
  angle = constrain(angle, 0, 180);
  uint32_t pulseUs = map(angle, 0, 180, 500, 2400);
  uint32_t maxDuty = (1UL << SERVO_RESOLUTION) - 1;
  return (pulseUs * maxDuty) / 20000UL;
}

// Pan was verified physically reversed earlier.
void setPan(int value) {
  value = constrain(value, 0, 180);
  panAngle = value;
  int physicalAngle = map(value, 0, 180, 150, 30);
  ledcWrite(PAN_SERVO_PIN, servoDuty(physicalAngle));
}

void setTilt(int value) {
  value = constrain(value, 0, 180);
  tiltAngle = value;
  int physicalAngle = map(value, 0, 180, 30, 150);
  ledcWrite(TILT_SERVO_PIN, servoDuty(physicalAngle));
}

// ============================================================
// MOTOR LOW LEVEL
// ============================================================

void setWheel(int wheel, int direction, int pwm) {
  if (wheel < 0 || wheel > 3) return;

  pwm = constrain(pwm, 0, 255);

  if (direction > 0) {
    digitalWrite(MOTOR_IN1[wheel], HIGH);
    digitalWrite(MOTOR_IN2[wheel], LOW);
  } else if (direction < 0) {
    digitalWrite(MOTOR_IN1[wheel], LOW);
    digitalWrite(MOTOR_IN2[wheel], HIGH);
  } else {
    digitalWrite(MOTOR_IN1[wheel], LOW);
    digitalWrite(MOTOR_IN2[wheel], LOW);
    pwm = 0;
  }

  ledcWrite(MOTOR_EN[wheel], pwm);
}

void stopMotorOutputs() {
  for (int i = 0; i < 4; i++) setWheel(i, 0, 0);
}

void kickPattern(int d0, int d1, int d2, int d3) {
  setWheel(0, d0, d0 == 0 ? 0 : 255);
  setWheel(1, d1, d1 == 0 ? 0 : 255);
  setWheel(2, d2, d2 == 0 ? 0 : 255);
  setWheel(3, d3, d3 == 0 ? 0 : 255);
  delay(MOTOR_KICK_MS);
}

void drivePattern(int d0, int d1, int d2, int d3, int pwm, bool kick) {
  if (pwm <= 0) {
    stopMotorOutputs();
    return;
  }

  if (kick) kickPattern(d0, d1, d2, d3);

  setWheel(0, d0, d0 == 0 ? 0 : pwm);
  setWheel(1, d1, d1 == 0 ? 0 : pwm);
  setWheel(2, d2, d2 == 0 ? 0 : pwm);
  setWheel(3, d3, d3 == 0 ? 0 : pwm);
}

// Normal LEFT/RIGHT are gentle forward curves.
void driveCurveLeft(int pwm, bool kick) {
  if (pwm <= 0) {
    stopMotorOutputs();
    return;
  }

  int insidePWM = max(90, (pwm * 55) / 100);
  if (kick) kickPattern(1, 1, 1, 1);

  setWheel(0, 1, insidePWM);
  setWheel(1, 1, insidePWM);
  setWheel(2, 1, pwm);
  setWheel(3, 1, pwm);
}

void driveCurveRight(int pwm, bool kick) {
  if (pwm <= 0) {
    stopMotorOutputs();
    return;
  }

  int insidePWM = max(90, (pwm * 55) / 100);
  if (kick) kickPattern(1, 1, 1, 1);

  setWheel(0, 1, pwm);
  setWheel(1, 1, pwm);
  setWheel(2, 1, insidePWM);
  setWheel(3, 1, insidePWM);
}

void applyDriveState(bool kick) {
  int pwm = activeMotorPWM();

  switch (driveState) {
    case DRIVE_FORWARD:
      drivePattern(1, 1, 1, 1, pwm, kick);
      break;

    case DRIVE_BACKWARD:
      drivePattern(-1, -1, -1, -1, pwm, kick);
      break;

    case DRIVE_CURVE_LEFT:
      driveCurveLeft(pwm, kick);
      break;

    case DRIVE_CURVE_RIGHT:
      driveCurveRight(pwm, kick);
      break;

    // Proven mecanum concept from the user's older controller:
    // LEFT  = - + + -
    // RIGHT = + - - +
    case DRIVE_STRAFE_LEFT:
      drivePattern(-1, 1, 1, -1, pwm, kick);
      break;

    case DRIVE_STRAFE_RIGHT:
      drivePattern(1, -1, -1, 1, pwm, kick);
      break;

    // Spin in place
    case DRIVE_SPIN_LEFT:
      drivePattern(-1, -1, 1, 1, pwm, kick);
      break;

    case DRIVE_SPIN_RIGHT:
      drivePattern(1, 1, -1, -1, pwm, kick);
      break;

    // Diagonal mecanum
    case DRIVE_DIAG_FL:
      drivePattern(0, 1, 1, 0, pwm, kick);
      break;

    case DRIVE_DIAG_FR:
      drivePattern(1, 0, 0, 1, pwm, kick);
      break;

    case DRIVE_DIAG_BL:
      drivePattern(-1, 0, 0, -1, pwm, kick);
      break;

    case DRIVE_DIAG_BR:
      drivePattern(0, -1, -1, 0, pwm, kick);
      break;

    default:
      stopMotorOutputs();
      break;
  }
}

void setDrive(DriveState requested, bool forceUpdate = false, bool forceKick = false) {
  if (requested == driveState && !forceUpdate) return;

  DriveState previous = driveState;

  if (previous != DRIVE_STOP && requested != DRIVE_STOP && requested != previous) {
    stopMotorOutputs();
    delay(25);
  }

  bool kick = forceKick || (requested != DRIVE_STOP && previous != requested);

  driveState = requested;
  applyDriveState(kick);
}

void stopDrive() {
  driveState = DRIVE_STOP;
  stopMotorOutputs();
}

// ============================================================
// MODE MANAGEMENT
// ============================================================

void resetPhoneCalibration() {
  phoneCalibrated = false;
  phoneCalibrationSamples = 0;
  phoneSumX = 0.0f;
  phoneSumY = 0.0f;
}

void setMode(RoverMode newMode) {
  if (roverMode == newMode) return;

  stopDrive();
  roverMode = newMode;
  autoAllBlocked = false;

  if (newMode != MODE_MOTION) resetPhoneCalibration();

  Serial.print("MODE -> ");
  Serial.println(modeName());
}

void enterIdle() {
  setMode(MODE_IDLE);
  stopDrive();
}

void emergencyStop() {
  roverMode = MODE_IDLE;
  stopDrive();
  autoAllBlocked = false;
  resetPhoneCalibration();

  headlightEnabled = false;
  automaticHeadlightOn = false;
  physicalHeadlightOn = false;
  digitalWrite(HEADLIGHT_PIN, LOW);

  userRgbEnabled = false;
  userBuzzerEnabled = false;

  Serial.println("!!! EMERGENCY STOP !!!");
}

// ============================================================
// ULTRASONIC / SENSOR
// ============================================================

float readDistanceCM(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(3);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  unsigned long duration = pulseIn(echoPin, HIGH, 30000);
  if (duration == 0) return -1.0f;

  float distance = duration * 0.0343f / 2.0f;
  if (distance < 2.0f || distance > 400.0f) return -1.0f;
  return distance;
}

float readFrontStable() {
  float total = 0.0f;
  int valid = 0;

  for (int i = 0; i < 3; i++) {
    float d = readDistanceCM(FRONT_TRIG, FRONT_ECHO);
    if (d > 0.0f) {
      total += d;
      valid++;
    }
    delay(35);
  }

  if (valid == 0) return -1.0f;
  return total / valid;
}

void updateSensors() {
  ldrValue = analogRead(LDR_PIN);

  frontDistance = readDistanceCM(FRONT_TRIG, FRONT_ECHO);
  delay(35);
  rearDistance = readDistanceCM(REAR_TRIG, REAR_ECHO);

  rightObstacle = digitalRead(RIGHT_IR_PIN) == LOW;
  frontObstacle = frontDistance > 0.0f && frontDistance <= FRONT_BLOCK_DISTANCE;
  rearObstacle = rearDistance > 0.0f && rearDistance <= REAR_BLOCK_DISTANCE;
  anyObstacle = frontObstacle || rearObstacle || rightObstacle;
}

// ============================================================
// AUTONOMOUS
// ============================================================

bool autonomousDelay(unsigned long duration) {
  unsigned long started = millis();

  while (millis() - started < duration) {
    server.handleClient();
    updateAutomaticHeadlight();
    updateHeadlightOutput();
    updateAccessoryOutputs();

    if (roverMode != MODE_AUTONOMOUS) {
      stopDrive();
      return false;
    }

    delay(2);
  }

  return true;
}

void runAutonomous() {
  if (roverMode != MODE_AUTONOMOUS) return;

  if (autoAllBlocked) {
    stopDrive();
    return;
  }

  if (millis() - lastAutoDecision < AUTO_DECISION_INTERVAL) return;
  lastAutoDecision = millis();

  float front = readDistanceCM(FRONT_TRIG, FRONT_ECHO);
  delay(35);
  float rear = readDistanceCM(REAR_TRIG, REAR_ECHO);

  bool rightBlocked = digitalRead(RIGHT_IR_PIN) == LOW;
  bool frontBlocked = front > 0.0f && front <= FRONT_BLOCK_DISTANCE;
  bool rearBlocked = rear > 0.0f && rear <= REAR_BLOCK_DISTANCE;

  // Front clear -> continue forward.
  if (!frontBlocked) {
    setDrive(DRIVE_FORWARD);
    return;
  }

  stopDrive();

  // Right clear -> rotate right.
  if (!rightBlocked) {
    setDrive(DRIVE_SPIN_RIGHT);
    if (!autonomousDelay(TURN_90_TIME)) return;
    stopDrive();
    autonomousDelay(120);
    return;
  }

  // Rear clear -> reverse then rotate left.
  if (!rearBlocked) {
    setDrive(DRIVE_BACKWARD);
    if (!autonomousDelay(BACKUP_TIME)) return;
    stopDrive();
    if (!autonomousDelay(100)) return;
    setDrive(DRIVE_SPIN_LEFT);
    if (!autonomousDelay(TURN_90_TIME)) return;
    stopDrive();
    autonomousDelay(120);
    return;
  }

  // Front + right + rear blocked -> physically inspect original left.
  Serial.println("Checking LEFT...");

  setDrive(DRIVE_SPIN_LEFT);
  if (!autonomousDelay(TURN_90_TIME)) return;

  stopDrive();
  if (!autonomousDelay(180)) return;

  float left = readFrontStable();
  bool leftBlocked = left > 0.0f && left <= LEFT_SCAN_DISTANCE;

  if (!leftBlocked) {
    Serial.println("LEFT CLEAR");
    setDrive(DRIVE_FORWARD);
    return;
  }

  Serial.println("ALL SIDES BLOCKED");
  autoAllBlocked = true;
  stopDrive();
}

// ============================================================
// PHONE MOTION
// ============================================================

void startMotionMode() {
  setMode(MODE_MOTION);
  resetPhoneCalibration();
  lastPhonePacket = millis();
  Serial.println("WAITING FOR PHONE MOTION");
}

void processPhoneMotion() {
  int packetSize = udp.parsePacket();
  if (packetSize <= 0) return;

  int len = udp.read(udpBuffer, sizeof(udpBuffer) - 1);
  if (len <= 0) return;

  udpBuffer[len] = '\0';

  int parsed = sscanf(udpBuffer, "%f,%f,%f", &phoneX, &phoneY, &phoneZ);
  if (parsed != 3) return;

  lastPhonePacket = millis();

  // UDP cannot control motors unless MOTION owns them.
  if (roverMode != MODE_MOTION) return;

  if (!phoneCalibrated) {
    phoneSumX += phoneX;
    phoneSumY += phoneY;
    phoneCalibrationSamples++;
    stopDrive();

    if (phoneCalibrationSamples >= 50) {
      phoneZeroX = phoneSumX / phoneCalibrationSamples;
      phoneZeroY = phoneSumY / phoneCalibrationSamples;
      phoneCalibrated = true;
      Serial.println("PHONE CALIBRATED");
    }
    return;
  }

  float x = phoneX - phoneZeroX;
  float y = phoneY - phoneZeroY;

  if (y < -phoneTiltThreshold) {
    setDrive(DRIVE_FORWARD);
  } else if (y > phoneTiltThreshold) {
    setDrive(DRIVE_BACKWARD);
  } else if (x < -phoneTiltThreshold) {
    setDrive(DRIVE_STRAFE_LEFT);
  } else if (x > phoneTiltThreshold) {
    setDrive(DRIVE_STRAFE_RIGHT);
  } else {
    setDrive(DRIVE_STOP);
  }
}

void updatePhoneFailsafe() {
  if (
    roverMode == MODE_MOTION &&
    phoneCalibrated &&
    millis() - lastPhonePacket > PHONE_TIMEOUT
  ) {
    stopDrive();
  }
}

// ============================================================
// MANUAL WEB CONTROL
// ============================================================

void manualCommand(DriveState command) {
  lastDashboardHeartbeat = millis();

  if (roverMode != MODE_MANUAL) setMode(MODE_MANUAL);

  // LATCHED: no automatic STOP on touch release.
  setDrive(command);
}

void updateDashboardFailsafe() {
  if (
    roverMode == MODE_MANUAL &&
    driveState != DRIVE_STOP &&
    millis() - lastDashboardHeartbeat > DASHBOARD_TIMEOUT
  ) {
    Serial.println("WEB LINK LOST -> STOP");
    stopDrive();
  }
}

// ============================================================
// OLED
// ============================================================

void updateOLED() {
  oled.clearBuffer();
  oled.setFont(u8g2_font_6x10_tf);
  oled.drawStr(2, 10, "ECOROVER");

  char buffer[32];

  snprintf(buffer, sizeof(buffer), "MODE: %s", modeName());
  oled.drawStr(2, 23, buffer);

  if (frontDistance > 0.0f) snprintf(buffer, sizeof(buffer), "FRONT: %.1f cm", frontDistance);
  else snprintf(buffer, sizeof(buffer), "FRONT: NO ECHO");
  oled.drawStr(2, 36, buffer);

  if (rearDistance > 0.0f) snprintf(buffer, sizeof(buffer), "REAR: %.1f cm", rearDistance);
  else snprintf(buffer, sizeof(buffer), "REAR: NO ECHO");
  oled.drawStr(2, 49, buffer);

  snprintf(
    buffer,
    sizeof(buffer),
    "SPD:%d%% OBJ:%s",
    manualSpeedPercent,
    (anyObstacle || autoAllBlocked) ? "YES" : "NO"
  );
  oled.drawStr(2, 62, buffer);

  oled.sendBuffer();
}

// ============================================================
// HTTP HELPERS
// ============================================================

void replyOK() {
  server.sendHeader("Cache-Control", "no-store");
  server.send(200, "text/plain", "OK");
}

void sendStatus() {
  // Status polling is the manual-mode heartbeat.
  lastDashboardHeartbeat = millis();

  String json;
  json.reserve(760);

  json += "{";

  json += "\"mode\":\"";
  json += modeName();
  json += "\",";

  json += "\"drive\":\"";
  json += driveName();
  json += "\",";

  json += "\"front\":";
  json += String(frontDistance, 1);
  json += ",";

  json += "\"rear\":";
  json += String(rearDistance, 1);
  json += ",";

  json += "\"rightObstacle\":";
  json += rightObstacle ? "true" : "false";
  json += ",";

  json += "\"obstacle\":";
  json += (anyObstacle || autoAllBlocked) ? "true" : "false";
  json += ",";

  json += "\"allBlocked\":";
  json += autoAllBlocked ? "true" : "false";
  json += ",";

  json += "\"ldr\":";
  json += String(ldrValue);
  json += ",";

  json += "\"headlight\":";
  json += physicalHeadlightOn ? "true" : "false";
  json += ",";

  json += "\"headlightManual\":";
  json += headlightEnabled ? "true" : "false";
  json += ",";

  json += "\"headlightAuto\":";
  json += automaticHeadlightOn ? "true" : "false";
  json += ",";

  json += "\"accessoriesLocked\":";
  json += automaticDriveMode() ? "true" : "false";
  json += ",";

  json += "\"buzzer\":";
  json += userBuzzerEnabled ? "true" : "false";
  json += ",";

  json += "\"rgb\":";
  json += userRgbEnabled ? "true" : "false";
  json += ",";

  json += "\"rgbColor\":\"";
  json += userRgbName;
  json += "\",";

  json += "\"pan\":";
  json += String(panAngle);
  json += ",";

  json += "\"tilt\":";
  json += String(tiltAngle);
  json += ",";

  json += "\"manualSpeed\":";
  json += String(manualSpeedPercent);
  json += ",";

  json += "\"autoSpeed\":";
  json += String(autoSpeedPercent);
  json += ",";

  json += "\"motionSensitivity\":";
  json += String(motionSensitivityPercent);
  json += ",";

  json += "\"phoneCalibrated\":";
  json += phoneCalibrated ? "true" : "false";
  json += ",";

  json += "\"clients\":";
  json += String(WiFi.softAPgetStationNum());

  json += "}";

  server.sendHeader("Cache-Control", "no-store");
  server.send(200, "application/json", json);
}

void sendConfig() {
  server.send(
    200,
    "application/json",
    "{\"controller\":\"192.168.4.1\",\"cameraStream\":\"http://192.168.4.200/stream\",\"motionPort\":2055}"
  );
}

void showDashboard() {
  // dashboard_gz.h contains only numeric compressed bytes.
  server.sendHeader("Content-Encoding", "gzip");
  server.sendHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  server.sendHeader("Pragma", "no-cache");
  server.send_P(
    200,
    "text/html; charset=utf-8",
    (PGM_P)DASHBOARD_GZ,
    DASHBOARD_GZ_LEN
  );
}

// ============================================================
// SERVER ROUTES
// ============================================================

void setupServer() {
  server.on("/", HTTP_GET, []() { showDashboard(); });
  server.on("/api/status", HTTP_GET, []() { sendStatus(); });
  server.on("/api/config", HTTP_GET, []() { sendConfig(); });

  server.on("/api/idle", HTTP_GET, []() {
    enterIdle();
    replyOK();
  });

  // MANUAL
  server.on("/api/manual/forward", HTTP_GET, []() {
    manualCommand(DRIVE_FORWARD);
    replyOK();
  });

  server.on("/api/manual/backward", HTTP_GET, []() {
    manualCommand(DRIVE_BACKWARD);
    replyOK();
  });

  // Normal LEFT/RIGHT = forward curves.
  server.on("/api/manual/left", HTTP_GET, []() {
    manualCommand(DRIVE_CURVE_LEFT);
    replyOK();
  });

  server.on("/api/manual/right", HTTP_GET, []() {
    manualCommand(DRIVE_CURVE_RIGHT);
    replyOK();
  });

  // FAST L/R = direct mecanum side movement.
  server.on("/api/manual/strafe-left", HTTP_GET, []() {
    manualCommand(DRIVE_STRAFE_LEFT);
    replyOK();
  });

  server.on("/api/manual/strafe-right", HTTP_GET, []() {
    manualCommand(DRIVE_STRAFE_RIGHT);
    replyOK();
  });

  server.on("/api/manual/spin-left", HTTP_GET, []() {
    manualCommand(DRIVE_SPIN_LEFT);
    replyOK();
  });

  server.on("/api/manual/spin-right", HTTP_GET, []() {
    manualCommand(DRIVE_SPIN_RIGHT);
    replyOK();
  });

  server.on("/api/manual/diag-fl", HTTP_GET, []() {
    manualCommand(DRIVE_DIAG_FL);
    replyOK();
  });

  server.on("/api/manual/diag-fr", HTTP_GET, []() {
    manualCommand(DRIVE_DIAG_FR);
    replyOK();
  });

  server.on("/api/manual/diag-bl", HTTP_GET, []() {
    manualCommand(DRIVE_DIAG_BL);
    replyOK();
  });

  server.on("/api/manual/diag-br", HTTP_GET, []() {
    manualCommand(DRIVE_DIAG_BR);
    replyOK();
  });

  server.on("/api/manual/stop", HTTP_GET, []() {
    if (roverMode == MODE_MANUAL) stopDrive();
    replyOK();
  });

  server.on("/api/manual/speed", HTTP_GET, []() {
    if (server.hasArg("percent")) {
      int previousSpeed = manualSpeedPercent;
      manualSpeedPercent = constrain(server.arg("percent").toInt(), 0, 100);

      if (roverMode == MODE_MANUAL && driveState != DRIVE_STOP) {
        bool kick = previousSpeed == 0 && manualSpeedPercent > 0;
        setDrive(driveState, true, kick);
      }
    }
    replyOK();
  });

  // AUTONOMOUS
  server.on("/api/auto/start", HTTP_GET, []() {
    autoAllBlocked = false;
    setMode(MODE_AUTONOMOUS);
    replyOK();
  });

  server.on("/api/auto/stop", HTTP_GET, []() {
    if (roverMode == MODE_AUTONOMOUS) enterIdle();
    replyOK();
  });

  server.on("/api/auto/speed", HTTP_GET, []() {
    if (server.hasArg("percent")) {
      int previousSpeed = autoSpeedPercent;
      autoSpeedPercent = constrain(server.arg("percent").toInt(), 0, 100);

      if (roverMode == MODE_AUTONOMOUS && driveState != DRIVE_STOP) {
        bool kick = previousSpeed == 0 && autoSpeedPercent > 0;
        setDrive(driveState, true, kick);
      }
    }
    replyOK();
  });

  // MOTION
  server.on("/api/motion/start", HTTP_GET, []() {
    startMotionMode();
    replyOK();
  });

  server.on("/api/motion/stop", HTTP_GET, []() {
    if (roverMode == MODE_MOTION) enterIdle();
    replyOK();
  });

  server.on("/api/motion/sensitivity", HTTP_GET, []() {
    if (server.hasArg("percent")) {
      motionSensitivityPercent = constrain(server.arg("percent").toInt(), 10, 100);

      phoneTiltThreshold = 4.2f - (motionSensitivityPercent / 100.0f) * 3.2f;
      phoneTiltThreshold = constrain(phoneTiltThreshold, 1.0f, 4.0f);
    }
    replyOK();
  });

  // SERVO
  server.on("/api/pan", HTTP_GET, []() {
    if (server.hasArg("angle")) setPan(server.arg("angle").toInt());
    replyOK();
  });

  server.on("/api/tilt", HTTP_GET, []() {
    if (server.hasArg("angle")) setTilt(server.arg("angle").toInt());
    replyOK();
  });

  // RGB
  server.on("/api/rgb/color", HTTP_GET, []() {
    if (!automaticDriveMode() && server.hasArg("name")) {
      chooseRGBColor(server.arg("name"));
    }
    replyOK();
  });

  server.on("/api/rgb/on", HTTP_GET, []() {
    if (!automaticDriveMode()) userRgbEnabled = true;
    replyOK();
  });

  server.on("/api/rgb/off", HTTP_GET, []() {
    if (!automaticDriveMode()) userRgbEnabled = false;
    replyOK();
  });

  // BUZZER
  server.on("/api/buzzer/on", HTTP_GET, []() {
    if (!automaticDriveMode()) userBuzzerEnabled = true;
    replyOK();
  });

  server.on("/api/buzzer/off", HTTP_GET, []() {
    if (!automaticDriveMode()) userBuzzerEnabled = false;
    replyOK();
  });

  // HEADLIGHT
  server.on("/api/headlight/on", HTTP_GET, []() {
    if (!automaticDriveMode()) setHeadlight(true);
    replyOK();
  });

  server.on("/api/headlight/off", HTTP_GET, []() {
    if (!automaticDriveMode()) setHeadlight(false);
    replyOK();
  });

  // EMERGENCY
  server.on("/api/emergency", HTTP_GET, []() {
    emergencyStop();
    replyOK();
  });

  server.onNotFound([]() {
    server.send(404, "text/plain", "NOT FOUND");
  });

  server.begin();
  Serial.println("WEB SERVER READY");
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(2200);

  Serial.println();
  Serial.println("================================");
  Serial.println("       ECOROVER MASTER V6");
  Serial.println("================================");

  analogReadResolution(12);

  pinMode(HEADLIGHT_PIN, OUTPUT);
  digitalWrite(HEADLIGHT_PIN, LOW);
  setHeadlight(false);

  pinMode(BUZZER_PIN, OUTPUT);
  buzzerOff();

  // 3 blue flashes mean controller booted.
  startupRGB();

  pinMode(FRONT_TRIG, OUTPUT);
  pinMode(FRONT_ECHO, INPUT);
  pinMode(REAR_TRIG, OUTPUT);
  pinMode(REAR_ECHO, INPUT);
  pinMode(RIGHT_IR_PIN, INPUT_PULLUP);

  digitalWrite(FRONT_TRIG, LOW);
  digitalWrite(REAR_TRIG, LOW);

  for (int i = 0; i < 4; i++) {
    pinMode(MOTOR_IN1[i], OUTPUT);
    pinMode(MOTOR_IN2[i], OUTPUT);
    digitalWrite(MOTOR_IN1[i], LOW);
    digitalWrite(MOTOR_IN2[i], LOW);
  }

  // OLED / I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);
  delay(300);

  oled.setI2CAddress(0x3C * 2);
  oled.begin();
  oled.setPowerSave(0);

  // Motor PWM
  bool flOK = ledcAttachChannel(FL_EN, MOTOR_FREQ, MOTOR_RESOLUTION, CH_FL);
  bool rlOK = ledcAttachChannel(RL_EN, MOTOR_FREQ, MOTOR_RESOLUTION, CH_RL);
  bool frOK = ledcAttachChannel(FR_EN, MOTOR_FREQ, MOTOR_RESOLUTION, CH_FR);
  bool rrOK = ledcAttachChannel(RR_EN, MOTOR_FREQ, MOTOR_RESOLUTION, CH_RR);

  Serial.print("FL PWM: "); Serial.println(flOK ? "OK" : "FAILED");
  Serial.print("RL PWM: "); Serial.println(rlOK ? "OK" : "FAILED");
  Serial.print("FR PWM: "); Serial.println(frOK ? "OK" : "FAILED");
  Serial.print("RR PWM: "); Serial.println(rrOK ? "OK" : "FAILED");

  // Servo PWM
  bool panOK = ledcAttachChannel(PAN_SERVO_PIN, SERVO_FREQ, SERVO_RESOLUTION, CH_PAN);
  bool tiltOK = ledcAttachChannel(TILT_SERVO_PIN, SERVO_FREQ, SERVO_RESOLUTION, CH_TILT);

  Serial.print("PAN PWM: "); Serial.println(panOK ? "OK" : "FAILED");
  Serial.print("TILT PWM: "); Serial.println(tiltOK ? "OK" : "FAILED");

  setPan(90);
  setTilt(90);
  stopDrive();

  // Wi-Fi cold start sequence
  WiFi.mode(WIFI_OFF);
  delay(700);
  WiFi.mode(WIFI_AP);
  delay(400);
  WiFi.setSleep(false);

  WiFi.softAPConfig(AP_IP, AP_GATEWAY, AP_SUBNET);

  bool wifiOK = WiFi.softAP(
    WIFI_SSID,
    WIFI_PASSWORD,
    1,
    false,
    4
  );

  if (!wifiOK) {
    Serial.println("WIFI FAILED");
    return;
  }

  Serial.println("WIFI READY");
  Serial.print("IP: ");
  Serial.println(WiFi.softAPIP());

  udp.begin(UDP_PORT);
  Serial.print("UDP MOTION PORT: ");
  Serial.println(UDP_PORT);

  updateSensors();
  setupServer();

  lastDashboardHeartbeat = millis();

  Serial.println();
  Serial.println("Dashboard: http://192.168.4.1");
  Serial.println("Camera: http://192.168.4.200/stream");
  Serial.println("ECOROVER READY");
}

// ============================================================
// LOOP
// ============================================================

void loop() {
  unsigned long now = millis();

  server.handleClient();

  processPhoneMotion();
  updatePhoneFailsafe();
  updateDashboardFailsafe();

  if (now - lastSensorUpdate >= SENSOR_INTERVAL) {
    lastSensorUpdate = now;
    updateSensors();
  }

  updateAutomaticHeadlight();
  updateHeadlightOutput();
  updateAccessoryOutputs();
  runAutonomous();

  if (now - lastOLEDUpdate >= OLED_INTERVAL) {
    lastOLEDUpdate = now;
    updateOLED();
  }

  delay(1);
}
