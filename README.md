# iOS Testing Gym 🏋️‍♂️

Automation framework for iOS app testing through iPhone Mirroring on macOS, with a vision toward reinforcement learning integration.

## Demo

[![Demo Video](https://github.com/ebowwa/iOSTestingGym/raw/main/demo_thumbnail.png)](https://github.com/ebowwa/iOSTestingGym/raw/main/demo.mp4)

*Click the image above to watch the demo video (MP4, 8.3MB)*

## 🎯 What It Does Now

**iOS Testing Gym** provides:
- **Record & Replay**: Capture and replay user interactions with iPhone Mirroring
- **Relative Positioning**: Actions work even when window moves or resizes  
- **Screenshot Automation**: Capture screenshots for documentation or testing
- **Action Editing**: Modify recorded sequences, add annotations
- **Quick Actions**: One-click access to common tasks (Home, App Switcher)
- **Persistent Storage**: Save and organize test recordings

## 🔮 Future Vision: OpenAI Gym for iOS

The long-term goal is creating a reinforcement learning environment for iOS testing. See [VISION.md](docs/VISION.md) for the complete roadmap.

## 🏗️ Current Features

### iPhone Mirroring Control
- Window detection and automatic focus management
- Connection monitoring with quality indicators
- Accessibility permission handling

### Action Recording & Replay  
- Record user interactions with relative positioning
- Edit and annotate recorded sequences
- Three replay modes: Human (natural speed), Fast, Smart
- Export/import recordings for sharing

### Automation Actions
- **Taps & Clicks**: Precise coordinate-based interaction
- **Swipes**: Directional gestures and scrolling
- **Text Input**: Type or paste text
- **System Controls**: Home button, App Switcher

### Screenshot Management
- Capture screenshots during automation
- Multi-locale support
- Export formats: Flat, Organized, App Store Connect ready

### Mathematical Components (Available)
The project includes advanced mathematical components for future integration. See [TECHNICAL.md](docs/TECHNICAL.md) for details on:
- Signal processing (Kalman filter, low-pass filter)
- Gesture recognition algorithms  
- Coordinate transformation systems
- Dynamics simulation frameworks


## 🚀 Use Cases

- **Automated Testing**: Record once, replay across different scenarios
- **Screenshot Generation**: Capture App Store screenshots for all devices/locales
- **Regression Testing**: Verify UI behavior after changes
- **Demo Creation**: Record perfect app demonstrations
- **Repetitive Task Automation**: Automate routine testing workflows


## ⚠️ Important: iOS Platform Limitations

**See [iOS_AUTOMATION_LIMITATIONS.md](iOS_AUTOMATION_LIMITATIONS.md) for software-only limitations.**

### 🔬 Hardware HID Research (Experimental)
**See [HID_CONTROLLER_STATUS.md](docs/HID_CONTROLLER_STATUS.md)**

Exploring hardware solutions using ESP32-S3 as a USB HID controller for physical device control. Currently in research phase.

## 🔧 Technical Implementation

### Core Technologies
- **macOS**: Host platform for iPhone Mirroring (required - iOS cannot automate itself)
- **SwiftUI**: User interface framework
- **CoreGraphics**: Low-level event synthesis
- **ScreenCaptureKit**: Screenshot capture
- **Accessibility API**: System-level automation (macOS only)

### Key Components

#### Automation Controller (`iPhoneAutomation.swift`)
- Manages iPhone Mirroring connection
- Handles accessibility permissions
- Executes automation actions
- Monitors connection quality

#### Screenshot Manager (`ScreenshotManager.swift`)
- Captures app screenshots
- Manages multi-locale testing
- Exports in various formats
- Handles batch operations

#### Mathematical Engine (`TouchpadMathEngine.swift`)
- Processes touch input through mathematical pipeline
- Applies signal filtering and prediction
- Manages gesture recognition
- Handles coordinate transformations

#### Test Scenarios (`TestScenarios.swift`)
- Predefined action sequences
- Customizable test episodes
- Category-based organization
- Delay and timing control

## 🎮 Usage Example

```swift
// Initialize the automation system
let automation = iPhoneAutomation()

// Detect iPhone Mirroring
automation.detectiPhoneMirroring()

// Execute a test scenario
let scenario = PredefinedScenarios.openApp
Task {
    try await scenario.execute(with: automation)
}

// Capture screenshots
let screenshotManager = ScreenshotManager()
screenshotManager.captureAllScreenshots(
    for: runningApp,
    scenarios: TestScenario.defaultScenarios
)
```



## 🚦 Getting Started

### Prerequisites
- macOS 15.0 (Sequoia) or later - required for iPhone Mirroring
- Xcode 15.0 or later
- iPhone with iOS 17.0 or later
- iPhone and Mac on same Apple ID

### Installation

```bash
# Clone the repository
git clone https://github.com/ebowwa/iOSTestingGym.git
cd iOSTestingGym

# Open in Xcode
open iosAppTester.xcodeproj
```

### Setup
1. Build and run the app in Xcode (`Cmd+R`)
2. Grant accessibility permissions when prompted
3. Enable iPhone Mirroring:
   - Open iPhone Mirroring from Applications or Spotlight
   - Sign in with your Apple ID
   - Select your iPhone
4. The app will detect the iPhone Mirroring window automatically

### Required Permissions
- **Accessibility**: System Settings > Privacy & Security > Accessibility
- **Screen Recording**: System Settings > Privacy & Security > Screen Recording

The app will prompt for these permissions on first launch.

## 📸 Screenshot Testing Features

### Automated Screenshot Capture
- Capture screenshots of any running macOS application
- Configurable delays for UI interactions
- Preview, save, or copy screenshots
- Automatic screen recording permission management

### Export Formats
- **Organized**: Structured by App/Language/Device
- **Flat**: All screenshots in one folder
- **App Store Connect**: Formatted for App Store submission

### Capture Scenarios
- **Instant Capture**: Captures immediately (0.5s delay)
- **After 2 Seconds**: Allows time for UI interactions
- **After 5 Seconds**: For complex interactions or animations

## 🔮 Roadmap

See [VISION.md](docs/VISION.md) for the complete roadmap including OpenAI Gym integration and advanced features.

## 🏆 Key Features

- **Relative Positioning**: Recordings adapt to window movement and resizing
- **Visual Feedback**: See what's being recorded and replayed in real-time
- **Persistent Storage**: CoreData backend for managing recordings
- **Export/Import**: Share recordings as reusable test cases
- **No Jailbreak Required**: Works with standard iPhone Mirroring

## 📦 Project Structure

```
iosAppTester/
├── Models/           # Core automation logic
│   ├── ActionRecorder.swift      # Recording/replay system
│   ├── iPhoneAutomation.swift    # iPhone Mirroring control
│   └── ScreenshotManager.swift   # Screenshot capture
├── Views/            # SwiftUI interface
├── QuickActions/     # One-click automation actions
├── Mathematics/      # Mathematical components (future integration)
└── docs/            # Documentation
    ├── ARCHITECTURE.md         # System architecture
    ├── RECORD_REPLAY_VISION.md # Record/replay roadmap
    ├── TECHNICAL.md           # Mathematical framework
    └── VISION.md             # Future vision & roadmap
```

## 📝 Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System architecture and coordinate system
- [RECORD_REPLAY_VISION.md](docs/RECORD_REPLAY_VISION.md) - Advanced automation features roadmap
- [TECHNICAL.md](docs/TECHNICAL.md) - Mathematical components documentation
- [VISION.md](docs/VISION.md) - OpenAI Gym integration and future vision
- [iOS_AUTOMATION_LIMITATIONS.md](docs/iOS_AUTOMATION_LIMITATIONS.md) - Platform limitations

## 🤝 Contributing

Contributions are welcome! Key areas:
- Improving record/replay functionality
- Adding new Quick Actions
- OpenAI Gym environment wrapper (see [VISION.md](docs/VISION.md))
- Hardware HID controller development

Please open an issue to discuss major changes.

## 📜 License

MIT License

## 퉰f️ Author

Created by Elijah Arbee

---

*Making iOS app testing accessible through macOS automation, with a vision toward intelligent, learning-based testing.*
