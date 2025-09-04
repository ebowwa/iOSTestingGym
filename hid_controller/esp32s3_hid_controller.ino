/*
 * Seeed Studio ESP32-S3 HID Controller for iOS Automation
 * 
 * This turns your ESP32-S3 into a USB HID device that controls iOS via AssistiveTouch
 * 
 * Setup for Seeed Studio XIAO ESP32S3:
 * 1. Board: "XIAO_ESP32S3" or "ESP32S3 Dev Module"
 * 2. USB CDC On Boot: "Enabled" 
 * 3. USB Mode: "USB-OTG (TinyUSB)" 
 * 4. Upload Mode: "UART0/Hardware CDC"
 * 5. Install Adafruit TinyUSB Library
 */

#include "USB.h"
#include "USBHIDMouse.h"
#include "USBHIDKeyboard.h"
#include <WiFi.h>
#include <ArduinoJson.h>

USBHIDMouse Mouse;
USBHIDKeyboard Keyboard;

// WiFi credentials (for receiving commands from macOS)
const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";

WiFiServer server(8080);

// iOS screen dimensions (iPhone)
const int SCREEN_WIDTH = 390;
const int SCREEN_HEIGHT = 844;

// Current cursor position tracking
int currentX = 0;
int currentY = 0;

// Recording action structure
struct Action {
  enum Type {
    MOVE,
    CLICK,
    DRAG,
    WAIT,
    TYPE
  } type;
  
  float relX;      // 0.0 to 1.0
  float relY;      // 0.0 to 1.0
  float toRelX;    // For drag
  float toRelY;    // For drag
  int waitMs;
  String text;
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32-S3 iOS HID Controller Starting...");
  
  // Initialize USB HID
  USB.begin();
  Mouse.begin();
  Keyboard.begin();
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  
  // Start server
  server.begin();
  Serial.println("Server started on port 8080");
  Serial.println("\nSend commands to http://" + WiFi.localIP().toString() + ":8080");
  
  // Test sequence - home button action
  delay(3000);
  Serial.println("Executing test: Home button tap");
  executeHomeButtonTest();
}

void loop() {
  WiFiClient client = server.available();
  
  if (client) {
    Serial.println("Client connected");
    String request = client.readStringUntil('\r');
    client.flush();
    
    // Parse JSON command
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, request);
    
    if (!error) {
      executeCommand(doc);
    }
    
    client.stop();
  }
  
  // Also handle Serial commands for testing
  if (Serial.available()) {
    char cmd = Serial.read();
    handleSerialCommand(cmd);
  }
}

void executeCommand(JsonDocument& doc) {
  const char* type = doc["type"];
  
  if (strcmp(type, "move") == 0) {
    float x = doc["x"];
    float y = doc["y"];
    moveToPosition(x, y);
    
  } else if (strcmp(type, "click") == 0) {
    float x = doc["x"];
    float y = doc["y"];
    moveToPosition(x, y);
    delay(50);
    click();
    
  } else if (strcmp(type, "drag") == 0) {
    float fromX = doc["fromX"];
    float fromY = doc["fromY"];
    float toX = doc["toX"];
    float toY = doc["toY"];
    drag(fromX, fromY, toX, toY);
    
  } else if (strcmp(type, "type") == 0) {
    const char* text = doc["text"];
    typeText(text);
    
  } else if (strcmp(type, "recording") == 0) {
    // Execute a full recording
    JsonArray actions = doc["actions"];
    executeRecording(actions);
  }
}

void executeRecording(JsonArray& actions) {
  Serial.println("Executing recording...");
  
  for (JsonObject action : actions) {
    const char* type = action["type"];
    
    if (strcmp(type, "click") == 0) {
      float x = action["x"];
      float y = action["y"];
      moveToPosition(x, y);
      delay(100);
      click();
      
    } else if (strcmp(type, "drag") == 0) {
      float fromX = action["fromX"];
      float fromY = action["fromY"];
      float toX = action["toX"];
      float toY = action["toY"];
      drag(fromX, fromY, toX, toY);
      
    } else if (strcmp(type, "wait") == 0) {
      int ms = action["ms"];
      delay(ms);
    }
    
    delay(100); // Small delay between actions
  }
  
  Serial.println("Recording complete");
}

void moveToPosition(float relX, float relY) {
  // Convert relative (0-1) to absolute coordinates
  int targetX = (int)(relX * SCREEN_WIDTH);
  int targetY = (int)(relY * SCREEN_HEIGHT);
  
  // Calculate movement needed
  int dx = targetX - currentX;
  int dy = targetY - currentY;
  
  Serial.printf("Moving to %.2f, %.2f (dx:%d, dy:%d)\n", relX, relY, dx, dy);
  
  // Move in small steps for smooth movement
  int steps = 20;
  for (int i = 0; i < steps; i++) {
    Mouse.move(dx / steps, dy / steps, 0);
    delay(5);
  }
  
  currentX = targetX;
  currentY = targetY;
}

void click() {
  Serial.println("Click");
  Mouse.click(MOUSE_LEFT);
}

void rightClick() {
  Serial.println("Right click");
  Mouse.click(MOUSE_RIGHT);
}

void drag(float fromX, float fromY, float toX, float toY) {
  Serial.printf("Drag from %.2f,%.2f to %.2f,%.2f\n", fromX, fromY, toX, toY);
  
  moveToPosition(fromX, fromY);
  delay(100);
  
  Mouse.press(MOUSE_LEFT);
  delay(100);
  
  moveToPosition(toX, toY);
  delay(100);
  
  Mouse.release(MOUSE_LEFT);
}

void typeText(const char* text) {
  Serial.printf("Typing: %s\n", text);
  Keyboard.print(text);
}

void handleSerialCommand(char cmd) {
  switch(cmd) {
    case 'h':  // Home button test
      executeHomeButtonTest();
      break;
      
    case 'c':  // Center click test
      moveToPosition(0.5, 0.5);
      delay(100);
      click();
      break;
      
    case 's':  // Scroll test
      drag(0.5, 0.7, 0.5, 0.3);
      break;
      
    case 'r':  // Reset to top-left
      currentX = 0;
      currentY = 0;
      Serial.println("Reset position to 0,0");
      break;
      
    case 't':  // Type test
      typeText("Hello from ESP32-S3!");
      break;
      
    default:
      Serial.println("Commands: h=home, c=center, s=scroll, r=reset, t=type");
  }
}

void executeHomeButtonTest() {
  // The exact sequence from our macOS recordings
  // Step 1: Hover position (50% width, 5% height)
  moveToPosition(0.5, 0.05);
  delay(500);
  
  // Step 2: Click home button (85% width, 2% height)
  moveToPosition(0.85, 0.02);
  delay(100);
  click();
  
  delay(1000);
  Serial.println("Home button test complete");
}