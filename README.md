# iOS Testing Gym 🏋️‍♂️

Automation framework for iOS app testing through iPhone Mirroring on macOS, with a vision toward reinforcement learning integration.

## Demo

[![Demo Video](https://github.com/ebowwa/iOSTestingGym/raw/main/demo_thumbnail.png)](https://github.com/ebowwa/iOSTestingGym/raw/main/demo.mp4)

*Click the image above to watch the demo video (MP4, 8.3MB)*

## 🎯 What It Does

**iOS Testing Gym** automates iOS app testing through iPhone Mirroring on macOS:
- **Record & Replay** user interactions with relative positioning
- **Screenshot Automation** for App Store and documentation
- **Quick Actions** for common testing tasks
- **Persistent Storage** of test recordings

See [FEATURES.md](docs/FEATURES.md) for the complete feature list.

## 🔮 Vision

Long-term goal: Create an OpenAI Gym environment for iOS testing with reinforcement learning. See [VISION.md](docs/VISION.md) for the roadmap.


## ⚠️ Platform Limitations

- **iOS cannot automate itself** - Requires macOS with iPhone Mirroring
- See [iOS_AUTOMATION_LIMITATIONS.md](docs/iOS_AUTOMATION_LIMITATIONS.md) for details
- Hardware HID research in progress: [HID_CONTROLLER_STATUS.md](docs/HID_CONTROLLER_STATUS.md)



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

- [FEATURES.md](docs/FEATURES.md) - Complete feature list and capabilities
- [IMPLEMENTATION.md](docs/IMPLEMENTATION.md) - Technical implementation details
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System architecture and design
- [TECHNICAL.md](docs/TECHNICAL.md) - Mathematical components framework
- [VISION.md](docs/VISION.md) - Future roadmap and RL integration
- [RECORD_REPLAY_VISION.md](docs/RECORD_REPLAY_VISION.md) - Advanced automation roadmap
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
