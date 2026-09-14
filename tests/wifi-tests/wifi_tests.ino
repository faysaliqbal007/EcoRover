/*
   ============================================================
              ECOROVER WI-FI & UDP THROUGHPUT TEST SKETCH
   ============================================================
   Broadcasts SoftAP 'EcoRover' and monitors UDP packet reception
   on port 2055 to verify 33Hz phone motion latency.
*/

#include <WiFi.h>
#include <WiFiUdp.h>

const char* SSID = "EcoRover";
const char* PASS = "12345678";
const uint16_t UDP_PORT = 2055;

WiFiUDP udp;
char packetBuffer[255];
unsigned long packetCount = 0;
unsigned long lastReport = 0;

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(SSID, PASS);
  Serial.println("[TEST] EcoRover AP Started at 192.168.4.1");
  udp.begin(UDP_PORT);
  Serial.printf("[TEST] Listening for UDP packets on port %d\n", UDP_PORT);
}

void loop() {
  int packetSize = udp.parsePacket();
  if (packetSize) {
    int len = udp.read(packetBuffer, 254);
    if (len > 0) packetBuffer[len] = 0;
    packetCount++;
  }

  if (millis() - lastReport >= 1000) {
    Serial.printf("[UDP MONITOR] Packets received last second: %lu pkts/sec\n", packetCount);
    packetCount = 0;
    lastReport = millis();
  }
}
