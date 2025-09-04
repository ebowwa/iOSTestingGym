/*
 * XIAO ESP32S3 Sense - iOS HID Controller Test
 * 
 * Specific for Seeed Studio XIAO ESP32S3 Sense
 * 
 * Arduino IDE Settings:
 * - Board: "XIAO_ESP32S3" (after installing Seeed ESP32 boards)
 *   OR "ESP32S3 Dev Module" if Seeed boards not available
 * - USB CDC On Boot: "Enabled"
 * - USB Mode: "USB-OTG (TinyUSB)" ← CRITICAL!
 * - USB DFU On Boot: "Disabled"  
 * - Upload Mode: "UART0 / Hardware CDC"
 * - CPU Frequency: "240MHz (WiFi)"
 * - Flash Mode: "QIO 80MHz"
 * - Flash Size: "8MB (64Mb)"
 * - Partition Scheme: "8MB with spiffs (3MB APP/1.5MB SPIFFS)"
 * - PSRAM: "OPI PSRAM"
 */

#include "USB.h"
#include "USBHIDMouse.h"
#include "USBHIDKeyboard.h"
#include "xiao_esp32s3_sense_config.h"

USBHIDMouse Mouse;
USBHIDKeyboard Keyboard;

// Test state
bool testRunning = false;
int testPhase = 0;

void setup() {
  Serial.begin(115200);
  
  // Configure LED
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, LOW);
  
  // Initialize USB HID
  USB.begin();
  Mouse.begin();
  Keyboard.begin();
  
  // Wait for USB to enumerate
  delay(1000);
  
  Serial.println("\n========================================");
  Serial.println("XIAO ESP32S3 Sense - iOS HID Controller");
  Serial.println("========================================");
  Serial.println("\nSetup Instructions:");
  Serial.println("1. Enable AssistiveTouch on iOS:");
  Serial.println("   Settings > Accessibility > Touch > AssistiveTouch > ON");
  Serial.println("2. Connect XIAO to iOS device:");
  Serial.println("   - iPhone 14 or older: USB-C to Lightning adapter");
  Serial.println("   - iPhone 15+: USB-C cable directly");
  Serial.println("3. You should see a mouse cursor appear!\n");
  Serial.println("Commands (type in Serial Monitor):");
  Serial.println("  't' - Run test sequence");
  Serial.println("  'h' - Home button action (85%, 2%)");
  Serial.println("  'c' - Click center");
  Serial.println("  'm' - Move in square");
  Serial.println("  'd' - Drag test");
  Serial.println("  'k' - Keyboard test");
  Serial.println("========================================\n");
  
  // Blink LED 3 times to show ready
  for(int i = 0; i < 3; i++) {
    digitalWrite(BUILTIN_LED, HIGH);
    delay(200);
    digitalWrite(BUILTIN_LED, LOW);
    delay(200);
  }
}

void loop() {
  if (Serial.available()) {
    char cmd = Serial.read();
    executeCommand(cmd);
  }
  
  // Auto test every 10 seconds if enabled
  static unsigned long lastTest = 0;
  if (testRunning && millis() - lastTest > 10000) {
    runTestSequence();
    lastTest = millis();
  }
}

void executeCommand(char cmd) {
  digitalWrite(BUILTIN_LED, HIGH);
  
  switch(cmd) {
    case 't':
      Serial.println("Running full test sequence...");
      runTestSequence();
      break;
      
    case 'h':
      Serial.println("Executing home button tap (85%, 2%)...");
      homeButtonAction();
      break;
      
    case 'c':
      Serial.println("Clicking center...");
      moveToRelative(0.5, 0.5);
      delay(100);
      Mouse.click();
      break;
      
    case 'm':
      Serial.println("Moving in square pattern...");
      moveInSquare();
      break;
      
    case 'd':
      Serial.println("Drag test...");
      dragTest();
      break;
      
    case 'k':
      Serial.println("Keyboard test...");
      Keyboard.print("Hello from XIAO ESP32S3 Sense!");
      break;
      
    case 'r':
      Serial.println("Resetting position...");
      resetPosition();
      break;
      
    case 's':
      testRunning = !testRunning;
      Serial.println(testRunning ? "Auto-test enabled" : "Auto-test disabled");
      break;
      
    default:
      Serial.println("Unknown command. Type 't' for test, 'h' for help");
  }
  
  digitalWrite(BUILTIN_LED, LOW);
}

void moveToRelative(float relX, float relY) {
  // iOS screen dimensions (iPhone)
  const int SCREEN_WIDTH = 390;
  const int SCREEN_HEIGHT = 844;
  
  // Convert relative to pixels
  int targetX = (int)(relX * SCREEN_WIDTH);
  int targetY = (int)(relY * SCREEN_HEIGHT);
  
  Serial.print("Moving to ");
  Serial.print(relX * 100); Serial.print("%, ");
  Serial.print(relY * 100); Serial.println("%");
  
  // For now, move relative amount
  // In real use, we'd track absolute position
  Mouse.move(targetX / 4, targetY / 4);
}

void homeButtonAction() {
  // The exact sequence from macOS recordings
  
  // Step 1: Move to hover position (50%, 5%)
  Serial.println("  1. Hover at 50%, 5%");
  moveToRelative(0.5, 0.05);
  delay(500);
  
  // Step 2: Move to home button (85%, 2%)
  Serial.println("  2. Move to home button at 85%, 2%");
  moveToRelative(0.85, 0.02);
  delay(100);
  
  // Step 3: Click
  Serial.println("  3. Click!");
  Mouse.click();
  delay(1000);
  
  Serial.println("Home button action complete!");
}

void moveInSquare() {
  int steps = 30;
  int stepSize = 3;
  
  // Right
  for(int i = 0; i < steps; i++) {
    Mouse.move(stepSize, 0);
    delay(10);
  }
  
  // Down
  for(int i = 0; i < steps; i++) {
    Mouse.move(0, stepSize);
    delay(10);
  }
  
  // Left
  for(int i = 0; i < steps; i++) {
    Mouse.move(-stepSize, 0);
    delay(10);
  }
  
  // Up
  for(int i = 0; i < steps; i++) {
    Mouse.move(0, -stepSize);
    delay(10);
  }
  
  // Click to confirm
  Mouse.click();
}

void dragTest() {
  // Press and hold
  Serial.println("  Press...");
  Mouse.press();
  delay(100);
  
  // Move while pressed
  Serial.println("  Drag...");
  for(int i = 0; i < 50; i++) {
    Mouse.move(2, 1);
    delay(10);
  }
  
  // Release
  Serial.println("  Release!");
  Mouse.release();
}

void resetPosition() {
  // Move to top-left corner
  for(int i = 0; i < 100; i++) {
    Mouse.move(-10, -10);
    delay(5);
  }
}

void runTestSequence() {
  Serial.println("\n=== Running Test Sequence ===");
  
  // LED pattern to show test running
  for(int i = 0; i < 5; i++) {
    digitalWrite(BUILTIN_LED, HIGH);
    delay(100);
    digitalWrite(BUILTIN_LED, LOW);
    delay(100);
  }
  
  // Test 1: Move right and click
  Serial.println("Test 1: Move right and click");
  Mouse.move(100, 0);
  delay(500);
  Mouse.click();
  delay(1000);
  
  // Test 2: Move down and click
  Serial.println("Test 2: Move down and click");
  Mouse.move(0, 100);
  delay(500);
  Mouse.click();
  delay(1000);
  
  // Test 3: Drag
  Serial.println("Test 3: Drag gesture");
  Mouse.press();
  for(int i = 0; i < 30; i++) {
    Mouse.move(-3, -3);
    delay(20);
  }
  Mouse.release();
  delay(1000);
  
  // Test 4: Double click
  Serial.println("Test 4: Double click");
  Mouse.click();
  delay(100);
  Mouse.click();
  
  Serial.println("=== Test Complete ===\n");
}