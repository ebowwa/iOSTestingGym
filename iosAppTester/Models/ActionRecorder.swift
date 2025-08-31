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
        case mouseMove(x: CGFloat, y: CGFloat)
        case mouseClick(x: CGFloat, y: CGFloat, clickCount: Int)
        case mouseDown(x: CGFloat, y: CGFloat)
        case mouseUp(x: CGFloat, y: CGFloat)
        case mouseDrag(fromX: CGFloat, fromY: CGFloat, toX: CGFloat, toY: CGFloat)
        case keyPress(keyCode: UInt16, modifiers: UInt64)
        case wait(seconds: TimeInterval)
        
        var description: String {
            switch self {
            case .mouseMove(let x, let y):
                return "Move to (\(Int(x)), \(Int(y)))"
            case .mouseClick(let x, let y, let count):
                return "Click\(count > 1 ? " x\(count)" : "") at (\(Int(x)), \(Int(y)))"
            case .mouseDown(let x, let y):
                return "Mouse down at (\(Int(x)), \(Int(y)))"
            case .mouseUp(let x, let y):
                return "Mouse up at (\(Int(x)), \(Int(y)))"
            case .mouseDrag(let fx, let fy, let tx, let ty):
                return "Drag from (\(Int(fx)), \(Int(fy))) to (\(Int(tx)), \(Int(ty)))"
            case .keyPress(let code, _):
                return "Key press: \(code)"
            case .wait(let seconds):
                return "Wait \(seconds)s"
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
            currentActions.append(.mouseDown(x: screenLocation.x, y: screenLocation.y))
            
        case .leftMouseUp:
            if isDragging, let startPoint = dragStartPoint {
                // Record as drag if mouse moved significantly
                let distance = hypot(screenLocation.x - startPoint.x, screenLocation.y - startPoint.y)
                if distance > 5 {
                    currentActions.append(.mouseDrag(
                        fromX: startPoint.x,
                        fromY: startPoint.y,
                        toX: screenLocation.x,
                        toY: screenLocation.y
                    ))
                } else {
                    // Just a click
                    currentActions.append(.mouseClick(
                        x: screenLocation.x,
                        y: screenLocation.y,
                        clickCount: event.clickCount
                    ))
                }
            } else {
                currentActions.append(.mouseUp(x: screenLocation.x, y: screenLocation.y))
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
                    currentActions.append(.mouseMove(x: screenLocation.x, y: screenLocation.y))
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
        
        // Calculate offset if window has moved
        let xOffset = currentWindowBounds.origin.x - recording.windowBounds.origin.x
        let yOffset = currentWindowBounds.origin.y - recording.windowBounds.origin.y
        
        for action in recording.actions {
            await executeAction(action, xOffset: xOffset, yOffset: yOffset)
        }
        
        print("✅ Replay complete")
    }
    
    private func executeAction(_ action: RecordedAction, xOffset: CGFloat, yOffset: CGFloat) async {
        switch action {
        case .mouseMove(let x, let y):
            let adjustedPoint = CGPoint(x: x + xOffset, y: y + yOffset)
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseClick(let x, let y, let count):
            let adjustedPoint = CGPoint(x: x + xOffset, y: y + yOffset)
            MouseController.click(at: adjustedPoint, clickCount: count)
            
        case .mouseDown(let x, let y):
            let adjustedPoint = CGPoint(x: x + xOffset, y: y + yOffset)
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseUp(let x, let y):
            let adjustedPoint = CGPoint(x: x + xOffset, y: y + yOffset)
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseDrag(let fx, let fy, let tx, let ty):
            MouseController.swipe(
                from: CGPoint(x: fx + xOffset, y: fy + yOffset),
                to: CGPoint(x: tx + xOffset, y: ty + yOffset),
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