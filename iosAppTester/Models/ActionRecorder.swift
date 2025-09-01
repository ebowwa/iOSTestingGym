//
//  ActionRecorder.swift
//  iosAppTester
//
//  Records user interactions for replay automation
//

import Foundation
import AppKit
import CoreGraphics

class ActionRecorder: ObservableObject {
    
    // MARK: - Types
    
    enum RecordedAction: Codable {
        // Store both absolute and relative positions
        case mouseMove(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseClick(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat, clickCount: Int)
        case mouseDown(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseUp(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseDrag(fromX: CGFloat, fromY: CGFloat, toX: CGFloat, toY: CGFloat, 
                       fromRelX: CGFloat, fromRelY: CGFloat, toRelX: CGFloat, toRelY: CGFloat)
        case keyPress(keyCode: UInt16, modifiers: UInt64)
        case wait(seconds: TimeInterval)
        
        var description: String {
            switch self {
            case .mouseMove(_, _, let relX, let relY):
                return "Move to (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseClick(_, _, let relX, let relY, let count):
                return "Click\(count > 1 ? " x\(count)" : "") at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseDown(_, _, let relX, let relY):
                return "Mouse down at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseUp(_, _, let relX, let relY):
                return "Mouse up at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseDrag(_, _, _, _, let fRelX, let fRelY, let tRelX, let tRelY):
                return "Drag from (\(Int(fRelX*100))%, \(Int(fRelY*100))%) to (\(Int(tRelX*100))%, \(Int(tRelY*100))%)"
            case .keyPress(let code, _):
                return "Key press: \(code)"
            case .wait(let seconds):
                return "Wait \(String(format: "%.1f", seconds))s"
            }
        }
    }
    
    struct Recording: Codable {
        let id: UUID
        let name: String
        let windowBounds: CGRect
        let actions: [RecordedAction]
        let recordedAt: Date
        
        init(name: String, windowBounds: CGRect, actions: [RecordedAction], recordedAt: Date) {
            self.id = UUID()
            self.name = name
            self.windowBounds = windowBounds
            self.actions = actions
            self.recordedAt = recordedAt
        }
        
        var duration: TimeInterval {
            actions.compactMap { action in
                if case .wait(let seconds) = action {
                    return seconds
                }
                return nil
            }.reduce(0, +)
        }
    }
    
    // MARK: - Properties
    
    @Published var isRecording = false
    @Published var recordings: [Recording] = []
    @Published var currentActions: [RecordedAction] = []
    
    private var eventMonitor: Any?
    private var windowBounds: CGRect?
    private var lastActionTime: Date?
    private var lastMousePosition: CGPoint?
    private var isDragging = false
    private var dragStartPoint: CGPoint?
    
    // MARK: - Recording
    
    func startRecording(windowBounds: CGRect) {
        guard !isRecording else { return }
        
        self.windowBounds = windowBounds
        self.currentActions = []
        self.lastActionTime = Date()
        self.isRecording = true
        
        print("🔴 Recording started for window at \(windowBounds)")
        
        // Monitor global events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .mouseMoved, .keyDown],
            handler: handleEvent
        )
    }
    
    func stopRecording(name: String? = nil) {
        guard isRecording else { return }
        
        isRecording = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Save recording
        if !currentActions.isEmpty, let bounds = windowBounds {
            let recording = Recording(
                name: name ?? "Recording \(recordings.count + 1)",
                windowBounds: bounds,
                actions: currentActions,
                recordedAt: Date()
            )
            recordings.append(recording)
            saveRecordings()
            
            print("⏹ Recording stopped: \(currentActions.count) actions recorded")
        }
        
        windowBounds = nil
        lastActionTime = nil
    }
    
    private func handleEvent(_ event: NSEvent) {
        guard isRecording,
              let windowBounds = windowBounds else { return }
        
        let location = event.locationInWindow
        let screenLocation = NSEvent.mouseLocation
        
        // Check if event is within our window bounds
        let windowRect = NSRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y,
            width: windowBounds.width,
            height: windowBounds.height
        )
        
        guard windowRect.contains(screenLocation) else { return }
        
        // Add wait time since last action
        if let lastTime = lastActionTime {
            let timeDiff = Date().timeIntervalSince(lastTime)
            if timeDiff > 0.1 { // Only add wait if more than 100ms
                currentActions.append(.wait(seconds: timeDiff))
            }
        }
        
        // Record the action
        switch event.type {
        case .leftMouseDown:
            isDragging = true
            dragStartPoint = screenLocation
            // Calculate relative position within window
            let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
            let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
            currentActions.append(.mouseDown(
                x: screenLocation.x, 
                y: screenLocation.y, 
                relativeX: relX, 
                relativeY: relY
            ))
            
        case .leftMouseUp:
            if isDragging, let startPoint = dragStartPoint {
                // Record as drag if mouse moved significantly
                let distance = hypot(screenLocation.x - startPoint.x, screenLocation.y - startPoint.y)
                if distance > 5 {
                    let fromRelX = (startPoint.x - windowBounds.origin.x) / windowBounds.width
                    let fromRelY = (startPoint.y - windowBounds.origin.y) / windowBounds.height
                    let toRelX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let toRelY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    currentActions.append(.mouseDrag(
                        fromX: startPoint.x,
                        fromY: startPoint.y,
                        toX: screenLocation.x,
                        toY: screenLocation.y,
                        fromRelX: fromRelX,
                        fromRelY: fromRelY,
                        toRelX: toRelX,
                        toRelY: toRelY
                    ))
                } else {
                    // Just a click
                    let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    currentActions.append(.mouseClick(
                        x: screenLocation.x,
                        y: screenLocation.y,
                        relativeX: relX,
                        relativeY: relY,
                        clickCount: event.clickCount
                    ))
                }
            } else {
                let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                currentActions.append(.mouseUp(
                    x: screenLocation.x, 
                    y: screenLocation.y,
                    relativeX: relX,
                    relativeY: relY
                ))
            }
            isDragging = false
            dragStartPoint = nil
            
        case .leftMouseDragged:
            // Track dragging but don't record intermediate points
            break
            
        case .mouseMoved:
            // Only record significant moves
            if let lastPos = lastMousePosition {
                let distance = hypot(screenLocation.x - lastPos.x, screenLocation.y - lastPos.y)
                if distance > 20 { // Only record if moved more than 20 pixels
                    let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    currentActions.append(.mouseMove(
                        x: screenLocation.x, 
                        y: screenLocation.y,
                        relativeX: relX,
                        relativeY: relY
                    ))
                    lastMousePosition = screenLocation
                }
            } else {
                lastMousePosition = screenLocation
            }
            
        case .keyDown:
            currentActions.append(.keyPress(
                keyCode: event.keyCode,
                modifiers: UInt64(event.modifierFlags.rawValue)
            ))
            
        default:
            break
        }
        
        lastActionTime = Date()
    }
    
    // MARK: - Replay
    
    func replay(_ recording: Recording, in currentWindowBounds: CGRect) async {
        print("▶️ Replaying: \(recording.name)")
        print("📐 Original window: \(recording.windowBounds.size), Current: \(currentWindowBounds.size)")
        
        // Use relative positioning to handle both movement and resize
        for action in recording.actions {
            await executeAction(action, in: currentWindowBounds)
        }
        
        print("✅ Replay complete")
    }
    
    private func executeAction(_ action: RecordedAction, in windowBounds: CGRect) async {
        switch action {
        case .mouseMove(_, _, let relX, let relY):
            // Use relative position to calculate new absolute position
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseClick(_, _, let relX, let relY, let count):
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            MouseController.click(at: adjustedPoint, clickCount: count)
            
        case .mouseDown(_, _, let relX, let relY):
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseUp(_, _, let relX, let relY):
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseDrag(_, _, _, _, let fromRelX, let fromRelY, let toRelX, let toRelY):
            MouseController.swipe(
                from: CGPoint(
                    x: windowBounds.origin.x + (fromRelX * windowBounds.width),
                    y: windowBounds.origin.y + (fromRelY * windowBounds.height)
                ),
                to: CGPoint(
                    x: windowBounds.origin.x + (toRelX * windowBounds.width),
                    y: windowBounds.origin.y + (toRelY * windowBounds.height)
                ),
                duration: 0.5
            )
            
        case .keyPress(let keyCode, let modifiers):
            if let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: CGKeyCode(keyCode),
                keyDown: true
            ) {
                event.flags = CGEventFlags(rawValue: modifiers)
                event.post(tap: .cghidEventTap)
            }
            
            if let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: CGKeyCode(keyCode),
                keyDown: false
            ) {
                event.flags = CGEventFlags(rawValue: modifiers)
                event.post(tap: .cghidEventTap)
            }
            
        case .wait(let seconds):
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }
    
    // MARK: - Persistence
    
    private func saveRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("recordings.json")
        
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: filePath)
            print("💾 Saved \(recordings.count) recordings")
        } catch {
            print("❌ Failed to save recordings: \(error)")
        }
    }
    
    func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("recordings.json")
        
        do {
            let data = try Data(contentsOf: filePath)
            recordings = try JSONDecoder().decode([Recording].self, from: data)
            print("📂 Loaded \(recordings.count) recordings")
        } catch {
            print("ℹ️ No saved recordings found")
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
}