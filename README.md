# macOS Screenshot Tester

A macOS app for automated screenshot capture and testing of running applications. Built with SwiftUI and ScreenCaptureKit.

## Features

- 📸 **Automated Screenshot Capture** - Capture screenshots of any running macOS application
- ⏱️ **Configurable Delays** - Set delays before capture for interactions
- 🖼️ **Preview & Export** - Double-click to preview, save, or copy screenshots
- 🔒 **Permission Handling** - Automatic screen recording permission management
- 📂 **Multiple Export Formats** - Organized, flat, or App Store Connect formats

## Requirements

- macOS 13.0+
- Xcode 14.0+
- Screen Recording permission

## Installation

1. Clone the repository
2. Open `iosAppTester.xcodeproj` in Xcode
3. Build and run (⌘R)
4. Grant screen recording permission when prompted

## Usage

1. **Select App**: Choose a running app from the Apps tab
2. **Configure Scenarios**: Enable capture scenarios in Capture Settings
3. **Capture**: Click "Start Capture" to take screenshots
4. **Review**: View screenshots in the Screenshots tab
5. **Export**: Export screenshots in your preferred format

## Capture Scenarios

- **Instant Capture**: Captures immediately (0.5s delay)
- **After 2 Seconds**: Allows time for UI interactions
- **After 5 Seconds**: For complex interactions or animations

## Permissions

On first run, the app will request screen recording permission. You can grant this in:
**System Settings > Privacy & Security > Screen Recording**

## Export Options

- **Organized**: Structured by App/Language/Device
- **Flat**: All screenshots in one folder
- **App Store Connect**: Formatted for App Store submission

## Development

The app uses:
- SwiftUI for the interface
- ScreenCaptureKit for screenshot capture
- Modern Swift concurrency (async/await)

## License

MIT License

## Author

Created by Elijah Arbee