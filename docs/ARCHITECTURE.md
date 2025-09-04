# iOS Testing Gym - Architecture Documentation

## Action Pipeline Architecture

### Overview
The iOS Testing Gym uses a sophisticated pipeline for capturing, recording, and replaying user interactions with iPhone Mirroring. This pipeline ensures reliable automation regardless of window position or size changes.

## Core Concepts

### 1. Coordinate System
- **Dual Coordinate Storage**: Every action stores both absolute and relative positions
- **Relative Positioning**: Enables replay even when window moves or resizes
- **Top-Left Origin**: All coordinates use top-left origin (converted from NSEvent's bottom-left)

### 2. The Three-Step Pipeline

#### Recording Pipeline
When recording user actions, the system captures:

```
1. HOVER → 2. WAIT → 3. CLICK
```

**Example: Home Button Recording**
```swift
// Step 1: Mouse Move (Hover)
Position: (344.0, 66.2)
Relative: (50% width, 5% height)
Purpose: Reveals hidden toolbar

// Step 2: Wait
Duration: 0.5 seconds
Purpose: Allows toolbar animation to complete

// Step 3: Click
Position: (474.2, 41.48)  
Relative: (85% width, 2% height)
Purpose: Clicks the Home button
```

#### Replay Pipeline
During replay, actions are reconstructed from relative positions:

```swift
// Reconstruct absolute position from relative
let adjustedPoint = CGPoint(
    x: windowBounds.origin.x + (relX * windowBounds.width),
    y: windowBounds.origin.y + (relY * windowBounds.height)
)
```

### 3. Data Structures

#### RecordedAction Enum
Each action type stores both absolute and relative positions:

```swift
enum RecordedAction {
    case mouseMove(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
    case mouseClick(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat, clickCount: Int)
    case mouseDown(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
    case mouseUp(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
    case mouseDrag(fromX: CGFloat, fromY: CGFloat, toX: CGFloat, toY: CGFloat, 
                   fromRelX: CGFloat, fromRelY: CGFloat, toRelX: CGFloat, toRelY: CGFloat)
    case wait(seconds: TimeInterval)
    case windowMoved(from: CGRect, to: CGRect)  // Tracks window movement
}
```

#### Recording Struct
Recordings preserve the complete context:

```swift
struct Recording {
    let windowBounds: CGRect        // Original window position/size
    var actions: [RecordedAction]   // Sequence of actions
    var screenshotIds: [UUID]?      // Linked screenshots (optional)
    var locale: LocaleInfo?         // Locale at recording time (optional)
}
```

### 4. Persistence Layer (Core Data)

Recordings are persisted using Core Data for reliability:

- **Storage Location**: `~/Documents/Recordings.sqlite`
- **Automatic Save**: No risk of data loss on app closure
- **Migration Support**: Automatically migrates from old JSON format
- **Backward Compatibility**: Optional fields for future enhancements

### 5. Key Components

#### ActionRecorder
- **Captures**: Mouse events, keyboard input, timing
- **Filters**: Only records events within iPhone Mirroring window
- **Converts**: NSEvent coordinates (bottom-left) to top-left origin
- **Persists**: Saves to Core Data automatically

#### QuickActions
Pre-configured action sequences for common tasks:

- **HomeButtonAction**: Implements the hover→wait→click pipeline
- **AppSwitcherAction**: Similar pipeline for app switcher
- **ScreenshotAction**: Captures current iPhone screen

#### Replay System
- **Style Options**: Human (natural timing), Fast (minimal delays), Instant
- **Window Tracking**: Adjusts for window movement during replay
- **Progress Feedback**: Real-time status updates

## Coordinate Calculations

### Example: Home Button on 372x824 Window at (158, 25)

```
Window Origin: (158, 25)
Window Size: 372 x 824

Hover Position (50% width, 5% height):
X = 158 + (372 * 0.50) = 344.0
Y = 25 + (824 * 0.05) = 66.2

Click Position (85% width, 2% height):
X = 158 + (372 * 0.85) = 474.2
Y = 25 + (824 * 0.02) = 41.48
```

## Toolbar Interaction Pattern

The iPhone Mirroring toolbar is hidden by default and requires specific interaction:

1. **Hidden State**: Toolbar invisible initially
2. **Hover Trigger**: Mouse movement to top 5-10% of window
3. **Animation Delay**: 300-500ms for toolbar to fully appear
4. **Click Window**: Toolbar remains visible briefly after hover
5. **Positions**:
   - Home Button: 85% from left
   - App Switcher: ~52% from left
   - Screenshot: ~95% from left

## Best Practices

### Recording
- Ensure iPhone Mirroring window is focused
- Use deliberate, clear movements
- Add natural pauses between actions
- Annotate complex sequences

### Replay
- Verify window is visible before replay
- Use appropriate replay style for context
- Monitor progress for debugging
- Handle failures gracefully

## Troubleshooting

### Common Issues

1. **Home Button Not Working**
   - Verify hover duration (may need >500ms)
   - Check window focus state
   - Ensure toolbar area is not obscured

2. **Recording Missing Actions**
   - Check window bounds detection
   - Verify accessibility permissions
   - Ensure events are within window bounds

3. **Replay Inaccuracy**
   - Window may have moved (use relative positions)
   - Timing may need adjustment
   - Check for system UI interference

## Technical Notes

### Coordinate System Conversion
```swift
// NSEvent provides bottom-left origin
let mouseLocationBottomLeft = NSEvent.mouseLocation

// Convert to top-left origin for consistency
let screenHeight = NSScreen.main?.frame.height ?? 0
let mouseLocationTopLeft = CGPoint(
    x: mouseLocationBottomLeft.x,
    y: screenHeight - mouseLocationBottomLeft.y
)
```

### Event Filtering
Only mouse events within the iPhone Mirroring window bounds are recorded:
```swift
if !windowRect.contains(screenLocation) {
    return  // Skip events outside target window
}
```

### Timing Precision
- Minimum wait threshold: 100ms (shorter waits are ignored)
- Default hover wait: 500ms
- Click duration: 50ms between down/up events

## Future Enhancements

### Planned Features
- Screenshot synchronization with recordings
- Locale-aware replay for localization testing
- Visual feedback during recording
- Advanced gesture support (pinch, rotate)
- Network condition simulation

### Architecture Considerations
- Maintain backward compatibility
- Preserve relative positioning system
- Keep Core Data schema flexible
- Support migration paths

---

*Last Updated: September 2024*
*Version: 1.0*