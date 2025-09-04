# iOS Testing Gym - Implementation Details

## 🔧 Technical Implementation

### Core Technologies
- **macOS**: Host platform for iPhone Mirroring (required - iOS cannot automate itself)
- **SwiftUI**: User interface framework
- **CoreGraphics**: Low-level event synthesis
- **ScreenCaptureKit**: Screenshot capture
- **Accessibility API**: System-level automation (macOS only)
- **CoreData**: Persistent storage for recordings

### Key Components

#### Automation Controller (`iPhoneAutomation.swift`)
- Manages iPhone Mirroring connection
- Handles accessibility permissions
- Executes automation actions
- Monitors connection quality
- Window detection and focus management

#### Action Recorder (`ActionRecorder.swift`)
- Records user interactions with relative positioning
- Stores both absolute and relative coordinates
- Manages recording persistence with CoreData
- Provides replay with different modes (Human, Fast, Smart)
- Handles event filtering and optimization

#### Screenshot Manager (`ScreenshotManager.swift`)
- Captures app screenshots via ScreenCaptureKit
- Manages multi-locale testing
- Exports in various formats (Flat, Organized, App Store)
- Handles batch operations
- Permission management for screen recording

#### Test Scenarios (`TestScenarios.swift`)
- Predefined action sequences
- Customizable test episodes
- Category-based organization
- Delay and timing control

#### Quick Actions (`/QuickActions/`)
- One-click automation actions
- Protocol-based architecture
- Context-aware enabling/disabling
- Includes: Home button, App Switcher, Screenshot, Focus Window

### Coordinate System

#### Dual Coordinate Storage
Every action stores both:
- **Absolute coordinates**: Actual screen position
- **Relative coordinates**: Percentage-based (0.0 to 1.0)

#### Coordinate Transformation
```swift
// Recording: Convert absolute to relative
let relativeX = (absoluteX - windowBounds.origin.x) / windowBounds.width
let relativeY = (absoluteY - windowBounds.origin.y) / windowBounds.height

// Replay: Convert relative to absolute
let absoluteX = windowBounds.origin.x + (relativeX * windowBounds.width)
let absoluteY = windowBounds.origin.y + (relativeY * windowBounds.height)
```

#### Origin Conversion
- NSEvent uses bottom-left origin
- Window bounds use top-left origin
- Conversion handled automatically during recording

### Event Pipeline

#### Recording Pipeline
1. **Capture** - Monitor NSEvent stream
2. **Transform** - Convert coordinates to relative
3. **Filter** - Remove redundant events
4. **Store** - Save to CoreData with timestamps

#### Replay Pipeline
1. **Load** - Retrieve recording from CoreData
2. **Transform** - Convert relative to absolute coordinates
3. **Execute** - Post CGEvents
4. **Timing** - Respect delays between actions

### Data Persistence

#### CoreData Schema
- `RecordingEntity`: Stores recording metadata
- `actionsData`: JSON-encoded action array
- `windowBoundsData`: JSON-encoded CGRect
- `annotationsData`: Optional user annotations
- `screenshotIdsData`: Associated screenshots

#### Duplicate Prevention
- UUID-based recording identification
- Check for existing ID before saving
- Automatic duplicate cleanup on load

### Window Management

#### iPhone Mirroring Detection
```swift
// Search for iPhone Mirroring window
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
// Filter by owner name "iPhone Mirroring"
```

#### Dynamic Tracking
- Window position monitored during recording
- Automatic adjustment during replay
- Focus management before action execution

### Permission Handling

#### Required Permissions
1. **Accessibility** - For event synthesis
2. **Screen Recording** - For screenshots

#### Permission Flow
```swift
// Check permission
AXIsProcessTrustedWithOptions(options)

// Request if needed
CGRequestScreenCaptureAccess()
```

### Performance Optimizations

#### Event Filtering
- Consolidate rapid mouse movements
- Remove duplicate events
- Optimize wait times

#### Replay Modes
- **Human**: Natural speed with all movements
- **Fast**: Skip unnecessary movements
- **Smart**: Intelligent optimization (planned)

### Testing Infrastructure

#### Unit Tests
- Coordinate transformation accuracy
- Event filtering logic
- Recording/replay integrity

#### Integration Tests
- Window detection
- Permission handling
- Cross-app automation

### Known Limitations

#### Platform Constraints
- Requires macOS for iPhone Mirroring
- Cannot automate native iOS directly
- Limited to Accessibility API capabilities

#### Technical Constraints
- ~30ms latency for event posting
- Window must be visible and focused
- Some system UI elements restricted

### Future Optimizations

#### Planned Improvements
- Parallel action execution
- Smarter wait time detection
- Visual element recognition
- Network condition simulation

#### Performance Targets
- < 10ms event latency
- 60 FPS replay capability
- Zero recording data loss

## 🏗️ Build System

### Dependencies
- No external package dependencies
- Pure Swift/SwiftUI implementation
- System frameworks only

### Build Configuration
- **Minimum Deployment**: macOS 15.0
- **Swift Version**: 5.9+
- **Architecture**: Universal (Apple Silicon + Intel)

### Entitlements
```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
```

## 🐛 Debugging

### Common Issues

#### Window Not Found
- Ensure iPhone Mirroring is running
- Check window name matches exactly
- Verify window is on screen

#### Permission Denied
- Reset permissions in System Settings
- Restart app after granting
- Check entitlements are correct

#### Recording Failures
- Verify window bounds are valid
- Check CoreData is initialized
- Ensure sufficient disk space

### Debug Utilities

#### Scripts (`/scripts/`)
- `test_iphone_mirroring` - Test window detection
- `test_keyboard` - Verify keyboard input
- `test_home_button` - Test system controls
- `check_recordings.swift` - Validate recording data

### Logging

#### Log Levels
- 🟢 Success operations
- 🟡 Warnings
- 🔴 Errors
- 🔵 Debug info

#### Key Log Points
- Window detection
- Permission grants
- Action execution
- Recording save/load

## 📊 Metrics

### Performance Benchmarks
- Recording overhead: < 5% CPU
- Replay accuracy: > 99%
- Storage efficiency: ~1KB per action

### Quality Metrics
- Test coverage: Target > 80%
- Crash rate: < 0.1%
- Memory usage: < 100MB

## 🔒 Security Considerations

### Permission Model
- Explicit user consent required
- No background recording
- Local storage only

### Data Protection
- No network transmission
- No sensitive data logging
- User-controlled data lifecycle