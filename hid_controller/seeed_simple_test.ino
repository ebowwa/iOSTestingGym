/*
 * Simple HID Test for Seeed Studio XIAO ESP32S3
 * 
 * This minimal sketch tests if your ESP32-S3 can control iOS
 * 
 * Board Settings:
 * - Board: "XIAO_ESP32S3" (if you have Seeed boards installed)
 *   OR "ESP32S3 Dev Module" 
 * - USB CDC On Boot: "Enabled"
 * - USB Mode: "USB-OTG (TinyUSB)"
 */

#include "USB.h"
#include "USBHIDMouse.h"

USBHIDMouse Mouse;

// LED on Seeed XIAO ESP32S3
#define LED_PIN 21

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  
  // Start USB and Mouse
  USB.begin();
  Mouse.begin();
  
  Serial.println("Seeed XIAO ESP32S3 HID Test");
  Serial.println("============================");
  Serial.println("1. Enable AssistiveTouch on iOS");
  Serial.println("2. Connect this board to iOS via USB");
  Serial.println("3. You should see a cursor!");
  Serial.println("");
  Serial.println("This will move the mouse in a square every 3 seconds");
  
  delay(3000);
}

void loop() {
  // Blink LED to show we're running
  digitalWrite(LED_PIN, HIGH);
  
  Serial.println("Moving in square pattern...");
  
  // Move right
  for(int i = 0; i < 50; i++) {
    Mouse.move(2, 0);
    delay(10);
  }
  
  // Move down
  for(int i = 0; i < 50; i++) {
    Mouse.move(0, 2);
    delay(10);
  }
  
  // Move left
  for(int i = 0; i < 50; i++) {
    Mouse.move(-2, 0);
    delay(10);
  }
  
  // Move up
  for(int i = 0; i < 50; i++) {
    Mouse.move(0, -2);
    delay(10);
  }
  
  digitalWrite(LED_PIN, LOW);
  
  // Click to show we completed the square
  Mouse.click();
  Serial.println("Click!");
  
  delay(3000);
}