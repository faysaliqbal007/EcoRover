/*
   ============================================================
              ECOROVER SENSOR ACQUISITION TEST SKETCH
   ============================================================
   Reads Front/Rear HC-SR04, Right IR, and LDR sensors and logs
   calibrated values to the Serial Monitor at 10 Hz.
*/

#define LDR_PIN       4
#define HEADLIGHT_PIN 5
#define FRONT_TRIG    6
#define FRONT_ECHO    7
#define REAR_TRIG     10
#define REAR_ECHO     11
#define BUZZER_PIN    14
#define RIGHT_IR_PIN  15

long readUltrasonic(uint8_t trig, uint8_t echo) {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  long duration = pulseIn(echo, HIGH, 25000); // 25ms timeout (~4m)
  if (duration == 0) return -1;
  return duration / 58; // Convert to cm
}

void setup() {
  Serial.begin(115200);
  pinMode(FRONT_TRIG, OUTPUT); pinMode(FRONT_ECHO, INPUT);
  pinMode(REAR_TRIG, OUTPUT);  pinMode(REAR_ECHO, INPUT);
  pinMode(RIGHT_IR_PIN, INPUT_PULLUP);
  pinMode(HEADLIGHT_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  Serial.println("[TEST] EcoRover Sensor Diagnostic Started.");
}

void loop() {
  long frontDist = readUltrasonic(FRONT_TRIG, FRONT_ECHO);
  delay(30); // Prevent ultrasonic pulse cross-talk
  long rearDist  = readUltrasonic(REAR_TRIG, REAR_ECHO);
  int rightIR    = digitalRead(RIGHT_IR_PIN); // LOW = Obstacle
  int ldrVal     = analogRead(LDR_PIN);

  Serial.printf("[SENSORS] Front: %ld cm | Rear: %ld cm | Right IR: %s | LDR: %d\n",
                frontDist, rearDist, (rightIR == LOW ? "BLOCKED" : "CLEAR"), ldrVal);

  // Auto-headlight check
  if (ldrVal <= 100) {
    digitalWrite(HEADLIGHT_PIN, HIGH);
  } else if (ldrVal >= 250) {
    digitalWrite(HEADLIGHT_PIN, LOW);
  }

  delay(200);
}
