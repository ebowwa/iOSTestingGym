/*
 * Basic XIAO ESP32S3 Sense Test
 * Just blinks LED to verify board is working
 */

// XIAO ESP32S3 Sense has LED on GPIO21
#define LED 21

void setup() {
  Serial.begin(115200);
  pinMode(LED, OUTPUT);
  
  Serial.println("XIAO ESP32S3 Sense Basic Test");
  Serial.println("LED should blink every second");
}

void loop() {
  digitalWrite(LED, HIGH);
  Serial.println("LED ON");
  delay(1000);
  
  digitalWrite(LED, LOW);
  Serial.println("LED OFF");
  delay(1000);
}