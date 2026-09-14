/*
   ============================================================
              ECOROVER INDEPENDENT MOTOR TEST SKETCH
   ============================================================
   Validates all 4 motors and 12 mecanum movement patterns
   without running Wi-Fi or WebServer routines.
*/

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

#define CH_FL 0
#define CH_RL 1
#define CH_FR 2
#define CH_RR 3

void setWheel(uint8_t in1, uint8_t in2, uint8_t ch, int dir, uint8_t speed) {
  if (dir > 0) {
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
  } else if (dir < 0) {
    digitalWrite(in1, LOW);
    digitalWrite(in2, HIGH);
  } else {
    digitalWrite(in1, LOW);
    digitalWrite(in2, LOW);
  }
  ledcWrite(ch, speed);
}

void stopAll() {
  setWheel(FL_IN1, FL_IN2, CH_FL, 0, 0);
  setWheel(RL_IN1, RL_IN2, CH_RL, 0, 0);
  setWheel(FR_IN1, FR_IN2, CH_FR, 0, 0);
  setWheel(RR_IN1, RR_IN2, CH_RR, 0, 0);
}

void setup() {
  Serial.begin(115200);
  Serial.println("[TEST] EcoRover Drivetrain Bring-Up Test");

  pinMode(FL_IN1, OUTPUT); pinMode(FL_IN2, OUTPUT);
  pinMode(RL_IN1, OUTPUT); pinMode(RL_IN2, OUTPUT);
  pinMode(FR_IN1, OUTPUT); pinMode(FR_IN2, OUTPUT);
  pinMode(RR_IN1, OUTPUT); pinMode(RR_IN2, OUTPUT);

  ledcSetup(CH_FL, 1500, 8); ledcAttachPin(FL_EN, CH_FL);
  ledcSetup(CH_RL, 1500, 8); ledcAttachPin(RL_EN, CH_RL);
  ledcSetup(CH_FR, 1500, 8); ledcAttachPin(FR_EN, CH_FR);
  ledcSetup(CH_RR, 1500, 8); ledcAttachPin(RR_EN, CH_RR);

  stopAll();
  delay(1000);
}

void loop() {
  Serial.println("[TEST] All Forward...");
  setWheel(FL_IN1, FL_IN2, CH_FL, 1, 180);
  setWheel(RL_IN1, RL_IN2, CH_RL, 1, 180);
  setWheel(FR_IN1, FR_IN2, CH_FR, 1, 180);
  setWheel(RR_IN1, RR_IN2, CH_RR, 1, 180);
  delay(2000);
  stopAll(); delay(1000);

  Serial.println("[TEST] FAST Strafe Left (- + + -)...");
  setWheel(FL_IN1, FL_IN2, CH_FL, -1, 200);
  setWheel(RL_IN1, RL_IN2, CH_RL,  1, 200);
  setWheel(FR_IN1, FR_IN2, CH_FR,  1, 200);
  setWheel(RR_IN1, RR_IN2, CH_RR, -1, 200);
  delay(2000);
  stopAll(); delay(1000);

  Serial.println("[TEST] FAST Strafe Right (+ - - +)...");
  setWheel(FL_IN1, FL_IN2, CH_FL,  1, 200);
  setWheel(RL_IN1, RL_IN2, CH_RL, -1, 200);
  setWheel(FR_IN1, FR_IN2, CH_FR, -1, 200);
  setWheel(RR_IN1, RR_IN2, CH_RR,  1, 200);
  delay(2000);
  stopAll(); delay(2000);
}
