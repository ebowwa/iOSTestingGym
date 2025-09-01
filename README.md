# iOS Testing Gym 🏋️‍♂️

An OpenAI Gym-like environment for iOS app testing and automation through iPhone Mirroring on macOS.

## Demo

[![Demo Video](https://github.com/ebowwa/iOSTestingGym/raw/main/demo_thumbnail.png)](https://github.com/ebowwa/iOSTestingGym/raw/main/demo.mp4)

*Click the image above to watch the demo video (MP4, 8.3MB)*

## 🎯 Core Vision

A **reinforcement learning-ready environment** for iOS app testing where:
- **Environment**: iPhone Mirroring on macOS acts as the controlled environment
- **Actions**: Discrete action space (tap, swipe, type, paste, home, app switcher)
- **Observations**: Screenshots serve as state observations (visual feedback)
- **Episodes**: Test scenarios define sequences of actions
- **Rewards**: Could be derived from UI state changes, successful navigation, or task completion

## 🏗️ Architecture Components

### 1. iPhone Mirroring Automation Layer
- Direct control of iPhone via macOS's iPhone Mirroring feature
- Window detection and focus management
- Connection quality monitoring
- Accessibility API integration

### 2. Action Space
- **Mouse Control**: Taps, swipes, clicks
- **Keyboard Input**: Typing, shortcuts
- **System Controls**: Home button, app switcher
- **Gesture Recognition**: Complex gesture patterns

### 3. Observation Space
- Screenshot capture via ScreenCaptureKit
- Multi-locale support for internationalization testing
- Device-specific resolution handling
- Organized export formats (flat, hierarchical, App Store ready)

### 4. Mathematical Control Framework
- **Kalman Filtering**: Smooths noisy touch input, predicts next position
- **Spring-Damper Dynamics**: Natural cursor movement physics
- **Finite State Machines**: Control flow management
- **Gesture Recognition**: $1 algorithm for pattern matching
- **Coordinate Transformations**: Maps between touchpad and screen spaces
- **Probability Distributions**: Heat maps of touch patterns
- **Signal Processing**: Low-pass filters for input smoothing
- **Attractor Fields**: Snap-to-grid UI element targeting

## 🤖 Why It's Like OpenAI Gym

This framework creates a **Gym environment for iOS apps** where:

1. **RL agents can learn** to navigate apps, complete tasks, or test UI flows
2. **State representation is visual** (screenshots) - perfect for vision-based RL
3. **Action space is discrete** and well-defined
4. **Episodes are configurable** via test scenarios
5. **Mathematical framework** provides sophisticated control suitable for learning algorithms

## 🚀 Potential Applications

- **Automated UI Testing**: Train agents to explore app UIs and find bugs
- **Accessibility Testing**: Verify app usability for different interaction patterns
- **Localization QA**: Automated screenshot generation for all locales
- **User Flow Optimization**: Learn optimal paths through app workflows
- **Regression Testing**: Detect UI changes between app versions
- **Performance Testing**: Monitor app responsiveness under various interaction patterns

## 🧮 Mathematical Sophistication

The mathematical abstraction layer enables:
- **Predictive touch control** (Kalman filter anticipates user intent)
- **Natural gesture synthesis** (Spring dynamics, Bezier curves)
- **Intelligent UI interaction** (Attractor fields for element targeting)
- **Noise-resistant input** (Signal processing pipeline)

This allows AI agents to interact with iOS apps as naturally as humans, learning from visual feedback and improving interaction strategies over time.

## 🔧 Technical Implementation

### Core Technologies
- **macOS**: Host platform for iPhone Mirroring
- **SwiftUI**: User interface framework
- **CoreGraphics**: Low-level event synthesis
- **ScreenCaptureKit**: Screenshot capture
- **Accessibility API**: System-level automation

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

## 🔬 Research Applications

This framework enables research in:
- **Human-Computer Interaction**: Study user interaction patterns
- **UI/UX Optimization**: A/B testing through automated exploration
- **Accessibility Research**: Evaluate app usability for diverse users
- **ML/AI Testing**: Train models to test like humans
- **Quality Assurance**: Automated regression and compatibility testing

## 📊 Data Collection

The framework collects:
- Visual states (screenshots)
- Action sequences
- Timing information
- Touch heat maps
- Gesture patterns
- Connection quality metrics

## 🚦 Getting Started

### Prerequisites
- macOS 15.0 or later
- Xcode 15.0 or later
- iPhone with iOS 17.0 or later
- iPhone Mirroring enabled

### Setup
1. Clone the repository
2. Open `iosAppTester.xcodeproj` in Xcode
3. Grant accessibility permissions when prompted
4. Enable iPhone Mirroring on your Mac
5. Run the application

### Permissions Required
- **Accessibility**: For automation control
- **Screen Recording**: For screenshot capture

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

## 🔮 Future Possibilities

- **RL Agent Integration**: Connect to popular RL frameworks
- **Computer Vision**: Add object detection for UI elements
- **Natural Language**: Voice command integration
- **Cloud Testing**: Distributed testing across multiple devices
- **Analytics Dashboard**: Real-time testing metrics and insights

## 🏆 Key Innovation

This project bridges the gap between:
- **Traditional UI testing** (scripted, brittle)
- **Modern AI approaches** (learning, adaptive)
- **Mathematical control theory** (precise, predictable)

The result is a powerful platform for the next generation of iOS app testing, where AI agents can learn to test apps like human QA engineers, but with the consistency and scale only automation can provide.

## Development

The app uses:
- SwiftUI for the interface
- ScreenCaptureKit for screenshot capture
- Modern Swift concurrency (async/await)
- CoreGraphics for event synthesis
- Mathematical abstractions for control theory

## License

MIT License

## Author

Created by Elijah Arbee

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

---

*Built with the vision of making iOS app testing as sophisticated as training AI agents in virtual environments.*
