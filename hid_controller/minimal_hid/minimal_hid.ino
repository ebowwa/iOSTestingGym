/*
 * Absolute Minimal HID Test
 * Just moves mouse every 2 seconds
 */

#include "USB.h"
#include "USBHIDMouse.h"

USBHIDMouse Mouse;

void setup() {
  USB.begin();
  Mouse.begin();
  delay(2000); // Wait 2 seconds
}

void loop() {
  // Move mouse right 10 pixels
  Mouse.move(10, 0);
  delay(2000);
  
  // Move mouse left 10 pixels  
  Mouse.move(-10, 0);
  delay(2000);
}