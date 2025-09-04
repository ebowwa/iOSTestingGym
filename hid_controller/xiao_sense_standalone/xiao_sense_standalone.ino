/*
 * XIAO ESP32S3 Sense - iOS HID Controller (Standalone)
 * 
 * Arduino IDE Settings:
 * - Board: "XIAO_ESP32S3" or "ESP32S3 Dev Module"
 * - USB CDC On Boot: "Enabled"
 * - USB Mode: "USB-OTG (TinyUSB)" ← CRITICAL!
 * - Upload Mode: "UART0 / Hardware CDC"
 * - Flash Size: "8MB (64Mb)"
 * - PSRAM: "OPI PSRAM"
 */

#include "USB.h"
#include "USBHIDMouse.h"
#include "USBHIDKeyboard.h"

// XIAO ESP32S3 Sense built-in LED
#define BUILTIN_LED 21

USBHIDMouse Mouse;
USBHIDKeyboard Keyboard;

void setup() {
  Serial.begin(115200);
  
  // Configure LED
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, LOW);
  
  // Initialize USB HID
  USB.begin();
  Mouse.begin();
  Keyboard.begin();
  
  // Wait for USB
  delay(1000);
  
  Serial.println("\n========================================");
  Serial.println("XIAO ESP32S3 Sense - iOS HID Controller");
  Serial.println("========================================");
  Serial.println("\nSetup:");
  Serial.println("1. Enable AssistiveTouch on iOS");
  Serial.println("2. Connect XIAO to iPhone with adapter");
  Serial.println("3. You should see a mouse cursor!\n");
  Serial.println("Commands:");
  Serial.println("  't' - Test (moves mouse in square)");
  Serial.println("  'h' - Home button (85%, 2%)");
  Serial.println("  'c' - Click center");
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
    handleCommand(cmd);
  }
}

void handleCommand(char cmd) {
  digitalWrite(BUILTIN_LED, HIGH);
  
  switch(cmd) {
    case 't':
      Serial.println("Test: Moving in square...");
      testSquare();
      break;
      
    case 'h':
      Serial.println("Home button action...");
      homeButton();
      break;
      
    case 'c':
      Serial.println("Click center...");
      Mouse.click();
      break;
      
    default:
      Serial.println("Unknown command");
  }
  
  digitalWrite(BUILTIN_LED, LOW);
}

void testSquare() {
  // Move in a square pattern
  for(int j = 0; j < 4; j++) {
    for(int i = 0; i < 30; i++) {
      switch(j) {
        case 0: Mouse.move(3, 0); break;   // Right
        case 1: Mouse.move(0, 3); break;   // Down
        case 2: Mouse.move(-3, 0); break;  // Left
        case 3: Mouse.move(0, -3); break;  // Up
      }
      delay(10);
    }
    delay(200);
  }
  Mouse.click();
  Serial.println("Square complete!");
}

void homeButton() {
  // Based on macOS recordings: 85% width, 2% height
  // This is simplified - just moves to approximate position
  
  Serial.println("Moving to home button position...");
  
  // Move right (85% of screen width)
  for(int i = 0; i < 50; i++) {
    Mouse.move(5, 0);
    delay(10);
  }
  
  // Move up (2% from top = move up)
  for(int i = 0; i < 30; i++) {
    Mouse.move(0, -3);
    delay(10);
  }
  
  delay(500);
  
  Serial.println("Clicking!");
  Mouse.click();
  
  Serial.println("Home button complete!");
}