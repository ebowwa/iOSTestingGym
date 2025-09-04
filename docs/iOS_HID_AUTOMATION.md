# iOS Automation via USB HID

## The Breakthrough: iOS Accepts USB Mouse/Keyboard

iOS has built-in support for USB HID devices through AssistiveTouch:
- **USB Mouse** → Controls AssistiveTouch cursor
- **USB Keyboard** → Types into active fields
- **No jailbreak required** - this is standard iOS functionality

## How It Works

1. **iOS AssistiveTouch** (Settings → Accessibility → Touch → AssistiveTouch)
   - When enabled, USB/Bluetooth mice control an on-screen cursor
   - Mouse clicks become taps
   - Right-click becomes long press
   - Scroll wheel works

2. **HID Protocol**
   ```
   Mouse.move(dx, dy)  → Moves AssistiveTouch cursor
   Mouse.click()       → Taps at cursor position  
   Mouse.rightClick()  → Long press
   Keyboard.type()     → Types text
   ```

3. **Automation Flow**
   ```
   iOS Device ← USB/Lightning → HID Device (Arduino/Raspberry Pi)
                                     ↑
                              Control from app
   ```

## Implementation Options

### Option 1: Arduino-based HID Device
```cpp
#include <Mouse.h>
#include <Keyboard.h>

void setup() {
  Serial.begin(9600);
  Mouse.begin();
  Keyboard.begin();
}

void executeRecording() {
  // Move to coordinates
  Mouse.move(100, 50);  
  delay(100);
  
  // Click
  Mouse.click();
  delay(500);
  
  // Type
  Keyboard.print("Hello iOS");
}
```

### Option 2: Raspberry Pi Zero as USB Gadget
```python
import usb_hid
from adafruit_hid.mouse import Mouse
from adafruit_hid.keyboard import Keyboard

mouse = Mouse(usb_hid.devices)
keyboard = Keyboard(usb_hid.devices)

def execute_recording(actions):
    for action in actions:
        if action.type == "move":
            mouse.move(action.dx, action.dy)
        elif action.type == "click":
            mouse.click(Mouse.LEFT_BUTTON)
        elif action.type == "type":
            keyboard.send(action.text)
        time.sleep(action.delay)
```

### Option 3: iOS App + External HID Controller

```swift
// iOS app sends commands to HID device via:
// - Bluetooth/WiFi to controller
// - Controller converts to USB HID
// - USB HID controls iOS via AssistiveTouch

struct HIDCommand: Codable {
    enum CommandType: String, Codable {
        case move, click, type, drag
    }
    
    let type: CommandType
    let x: Int?
    let y: Int?
    let text: String?
}

// Send to HID controller
func sendToController(_ command: HIDCommand) {
    // Send via network to Raspberry Pi/Arduino
    let data = try! JSONEncoder().encode(command)
    connection.send(data)
}
```

## Hardware Requirements

### For Lightning iOS Devices:
- Lightning to USB Camera Adapter (official Apple)
- USB HID device (Arduino Leonardo, Pro Micro, or Raspberry Pi Zero)
- External power may be needed

### For USB-C iOS Devices (iPad Pro, iPhone 15+):
- Direct USB-C connection
- USB HID device

## The Architecture That ACTUALLY Works

```
macOS App (Records)
    ↓
Recording Data (JSON)
    ↓
iOS App (Coordinator)
    ↓ (WiFi/Bluetooth)
HID Controller (RPi/Arduino)
    ↓ (USB)
iOS Device (AssistiveTouch)
    ↓
Actual UI Automation
```

## Why This Works When Everything Else Doesn't

1. **No iOS sandbox violations** - using official Accessibility features
2. **No private APIs** - standard USB HID protocol
3. **No jailbreak** - built into iOS
4. **Actually controls the device** - not fake automation

## Proof of Concept

1. Enable AssistiveTouch on iOS device
2. Connect USB mouse via adapter
3. Mouse cursor appears and controls iOS
4. This can be automated via HID commands

## Next Steps

1. Build HID controller (Arduino or RPi Zero)
2. Create protocol for sending recordings to controller
3. Convert recording coordinates to mouse movements
4. Test with real iOS device

## This Changes Everything

We can actually build:
- Local iOS automation that runs on device
- No Mac required after initial recording
- Real touch automation, not simulation
- Works with any iOS app

The limitation wasn't iOS - it was thinking in terms of software-only solutions. Hardware HID is the key!