# ESP32-S3 HID Controller for iOS Automation

## Overview
This uses an ESP32-S3 as a USB HID device to control iOS through AssistiveTouch - providing REAL automation without jailbreak or private APIs.

## How It Works
```
macOS App (Records) → WiFi → ESP32-S3 → USB HID → iOS (AssistiveTouch)
```

## Hardware Requirements
- ESP32-S3 development board (with native USB support)
- USB-C to Lightning adapter (for older iPhones) or USB-C cable (iPhone 15+)
- iOS device with AssistiveTouch

## Setup

### 1. Arduino IDE Configuration
- Board: "ESP32S3 Dev Module"
- USB Mode: **"USB-OTG (TinyUSB)"** ← CRITICAL!
- USB CDC On Boot: "Enabled"
- USB DFU On Boot: "Disabled"
- Flash Size: Match your board (usually 4MB or 8MB)

### 2. Required Libraries
```
- TinyUSB (install from Library Manager)
- ArduinoJson (for parsing commands)
- WiFi (included with ESP32)
```

### 3. Upload the Code
1. Edit `esp32s3_hid_controller.ino`:
   - Set your WiFi SSID and password
   - Adjust screen dimensions if needed

2. Upload to ESP32-S3

3. Open Serial Monitor (115200 baud) to see IP address

### 4. iOS Setup
1. Settings → Accessibility → Touch → AssistiveTouch → ON
2. Connect ESP32-S3 to iOS device
3. You should see a mouse cursor appear!

## Testing

### Via Serial Monitor
Send these commands:
- `h` - Execute home button tap (85% width, 2% height)
- `c` - Click center of screen
- `s` - Scroll test (drag)
- `t` - Type test text
- `r` - Reset cursor position

### Via WiFi
```bash
# Compile the sender
g++ send_to_esp32.cpp -lcurl -o send_to_esp32

# Run it with your ESP32's IP
./send_to_esp32 192.168.1.XXX

# Or use curl directly
curl -X POST http://192.168.1.XXX:8080 \
  -d '{"type":"click","x":0.5,"y":0.5}'
```

## Recording Format
The ESP32 accepts the same recording format as our macOS app:
```json
{
  "type": "recording",
  "actions": [
    {"type": "click", "x": 0.85, "y": 0.02},
    {"type": "wait", "ms": 1000},
    {"type": "drag", "fromX": 0.5, "fromY": 0.7, "toX": 0.5, "toY": 0.3}
  ]
}
```

## Troubleshooting

### No cursor appears on iOS
- Make sure AssistiveTouch is ON
- Check USB Mode is set to "USB-OTG (TinyUSB)"
- Try unplugging and reconnecting

### ESP32 won't connect to WiFi
- Check SSID and password
- Make sure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)

### Commands not working
- Check Serial Monitor for ESP32 IP address
- Verify ESP32 and macOS are on same network
- Try serial commands first to test

## How The Coordinates Work
- All coordinates are relative (0.0 to 1.0)
- (0.85, 0.02) = 85% from left, 2% from top = Home button location
- Same coordinate system as macOS recordings!

## Security Note
The ESP32 opens a server on port 8080. Only use on trusted networks or add authentication.

## Next Steps
1. Test with your ESP32-S3
2. Export recordings from macOS app
3. Send recordings to ESP32
4. Watch real iOS automation happen!

This is ACTUAL automation - not simulation!