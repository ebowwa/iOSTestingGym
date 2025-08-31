//
//  TouchpadView.swift
//  iosAppTester
//
//  Virtual touchpad for controlling iPhone Mirroring
//

import SwiftUI
import AppKit

struct TouchpadView: View {
    @ObservedObject var automation: iPhoneAutomation
    @Binding var isExpanded: Bool
    @StateObject private var focusManager = AppFocusManager.shared
    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var lastDragLocation: CGPoint = .zero
    @State private var virtualCursorPosition: CGPoint = CGPoint(x: 186, y: 412) // Start at center of iPhone
    @State private var savedCursorPosition: CGPoint = CGPoint(x: 186, y: 412) // Saved position to return to
    @State private var currentPosition: CGPoint = .zero
    @State private var isMouseDown = false
    @State private var isHolding = false // Track if user is holding for movement
    @State private var holdStartTime: Date? = nil
    @State private var hasMoved = false // Track if cursor moved during hold
    
    // Touchpad acts like a laptop trackpad - relative movement
    let touchpadWidth: CGFloat = 250
    let touchpadHeight: CGFloat = 180
    let sensitivity: CGFloat = 1.0 // Reduced sensitivity from 2.0 to 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Touchpad Area
            ZStack {
                // Background - simple trackpad style
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(focusManager.canAcceptInput ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHolding ? Color.green.opacity(0.6) : (focusManager.canAcceptInput && automation.isConnected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)), lineWidth: isHolding ? 2 : 1)
                    )
                
                // Hold indicator - shows when holding for movement
                if isHolding && isDragging {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .position(currentPosition)
                        .animation(.easeOut(duration: 0.1), value: currentPosition)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .position(currentPosition)
                }
                
                // Instructions when not connected or not focused
                if !focusManager.canAcceptInput {
                    Text("App Not Focused")
                        .foregroundColor(.orange)
                } else if !automation.isConnected {
                    Text("Connect iPhone First")
                        .foregroundColor(.gray)
                } else if !isHolding {
                    Text("Hold to Control")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.caption)
                }
            }
            .frame(width: touchpadWidth, height: touchpadHeight)
            .contentShape(Rectangle())
            .opacity(isExpanded ? 1.0 : 0.5)
            .allowsHitTesting(isExpanded) // Completely disable interaction when collapsed
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard focusManager.canAcceptInput && isExpanded else { return }
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        guard focusManager.canAcceptInput && isExpanded else { return }
                        handleDragEnded(value)
                    }
            )
            .simultaneousGesture(
                // Long press to enable movement mode
                LongPressGesture(minimumDuration: 0.3)
                    .onChanged { _ in
                        guard focusManager.canAcceptInput && isExpanded else { return }
                        if !isHolding {
                            isHolding = true
                            holdStartTime = Date()
                            hasMoved = false
                            // Haptic feedback if available
                            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                        }
                    }
            )
            
            // Control buttons
            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    // Quick tap in center
                    Button(action: {
                        guard isExpanded else { return }
                        tapCenterAndReturn()
                    }) {
                        Label("Tap Center", systemImage: "hand.tap")
                    }
                    .disabled(!automation.isConnected || !focusManager.canAcceptInput || !isExpanded)
                    
                    // Home button
                    Button(action: {
                        guard isExpanded else { return }
                        pressHomeAndReturn()
                    }) {
                        Label("Home", systemImage: "house")
                    }
                    .disabled(!automation.isConnected || !focusManager.canAcceptInput || !isExpanded)
                    
                    // App Switcher
                    Button(action: {
                        guard isExpanded else { return }
                        openAppSwitcherAndReturn()
                    }) {
                        Label("Switcher", systemImage: "square.stack.3d.up")
                    }
                    .disabled(!automation.isConnected || !focusManager.canAcceptInput || !isExpanded)
                }
                
                // Reset cursor position
                Button(action: {
                    guard isExpanded else { return }
                    resetCursorPosition()
                }) {
                    Label("Reset Cursor to Center", systemImage: "arrow.counterclockwise")
                }
                .disabled(!automation.isConnected || !focusManager.canAcceptInput || !isExpanded)
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .opacity(isExpanded ? 1.0 : 0.5)
            
            // Coordinate display - show virtual cursor position
            HStack {
                Text("Cursor: X: \(Int(virtualCursorPosition.x)) Y: \(Int(virtualCursorPosition.y))")
                Spacer()
                if isHolding {
                    Text("HOLD MODE")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                } else if isDragging {
                    Text("Touch")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            
            // Compact instructions
            VStack(spacing: 5) {
                HStack(spacing: 15) {
                    Label("Hold to enable movement", systemImage: "hand.raised.fill")
                    Label("Drag while holding to move", systemImage: "cursorarrow.motionlines")
                }
                Label("Tap while holding to click", systemImage: "hand.tap")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Gesture Handlers
    
    // Removed handleHover - no hover functionality
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard automation.isConnected else { return }
        
        // Only process drag if in hold mode
        guard isHolding else { 
            // Record drag attempt for potential tap detection but don't process movement
            if !isDragging {
                isDragging = true
                dragStart = value.startLocation
                lastDragLocation = value.startLocation
            }
            return 
        }
        
        if !isDragging {
            // Start of drag while holding - record starting position
            isDragging = true
            dragStart = value.startLocation
            lastDragLocation = value.startLocation
            currentPosition = value.location
        } else {
            currentPosition = value.location
            
            // Calculate relative movement from last position
            let deltaX = (value.location.x - lastDragLocation.x) * sensitivity
            let deltaY = (value.location.y - lastDragLocation.y) * sensitivity
            
            // Update virtual cursor position with bounds checking
            virtualCursorPosition.x = min(372, max(0, virtualCursorPosition.x + deltaX))
            virtualCursorPosition.y = min(824, max(0, virtualCursorPosition.y + deltaY))
            
            lastDragLocation = value.location
            hasMoved = true
            
            // Move the actual cursor on the iPhone screen
            if let windowBounds = automation.getiPhoneMirroringWindow() {
                moveCursorTo(virtualCursorPosition, in: windowBounds)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard automation.isConnected else { return }
        
        let distance = sqrt(pow(value.location.x - dragStart.x, 2) + pow(value.location.y - dragStart.y, 2))
        
        if isHolding {
            // User was holding for movement
            if distance < 5 && !hasMoved {
                // It's a tap while holding - perform click at cursor position
                if let windowBounds = automation.getiPhoneMirroringWindow() {
                    automation.tapAt(x: virtualCursorPosition.x, y: virtualCursorPosition.y, in: windowBounds)
                    automation.log("👆 Clicked at cursor position", level: .info)
                }
            } else if hasMoved {
                // Moved cursor while holding
                savedCursorPosition = virtualCursorPosition
                automation.log("📱 Moved cursor via touchpad", level: .info)
            }
        } else {
            // Not holding - just a regular tap (do nothing)
            if distance < 5 {
                automation.log("ℹ️ Hold first to enable cursor control", level: .info)
            }
        }
        
        // Reset states
        isDragging = false
        isMouseDown = false
        isHolding = false
        holdStartTime = nil
        hasMoved = false
    }
    
    // MARK: - Helper Methods
    
    private func mapToiPhoneX(_ touchpadX: CGFloat) -> CGFloat {
        // For relative movement, this is no longer used for direct mapping
        return virtualCursorPosition.x
    }
    
    private func mapToiPhoneY(_ touchpadY: CGFloat) -> CGFloat {
        // For relative movement, this is no longer used for direct mapping
        return virtualCursorPosition.y
    }
    
    private func tapCenterAndReturn() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        // Save current position
        savedCursorPosition = virtualCursorPosition
        
        // Move to center and tap
        virtualCursorPosition = CGPoint(x: 186, y: 412)
        moveCursorTo(virtualCursorPosition, in: windowBounds)
        
        // Tap at center
        automation.tapAt(x: 186, y: 412, in: windowBounds)
        
        // Return to saved position after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.virtualCursorPosition = self.savedCursorPosition
            if let bounds = self.automation.getiPhoneMirroringWindow() {
                self.moveCursorTo(self.virtualCursorPosition, in: bounds)
            }
        }
    }
    
    private func pressHomeAndReturn() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        // Save current position
        savedCursorPosition = virtualCursorPosition
        
        // Press home
        _ = automation.pressHome()
        
        // Return cursor to saved position after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.virtualCursorPosition = self.savedCursorPosition
            self.moveCursorTo(self.virtualCursorPosition, in: windowBounds)
        }
    }
    
    private func openAppSwitcherAndReturn() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        // Save current position
        savedCursorPosition = virtualCursorPosition
        
        // Open app switcher
        _ = automation.openAppSwitcher()
        
        // Return cursor to saved position after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.virtualCursorPosition = self.savedCursorPosition
            self.moveCursorTo(self.virtualCursorPosition, in: windowBounds)
        }
    }
    
    private func moveCursorTo(_ position: CGPoint, in windowBounds: CGRect) {
        let absoluteX = windowBounds.origin.x + position.x
        let absoluteY = windowBounds.origin.y + position.y
        
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        ) {
            if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                moveEvent.postToPid(windowInfo.processID)
            }
        }
    }
    
    private func resetCursorPosition() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        // Reset to center
        virtualCursorPosition = CGPoint(x: 186, y: 412)
        savedCursorPosition = virtualCursorPosition
        moveCursorTo(virtualCursorPosition, in: windowBounds)
        
        automation.log("🎯 Cursor reset to center", level: .info)
    }
    
    private func sendMouseEvent(x: CGFloat, y: CGFloat, in windowBounds: CGRect, mouseDown: Bool) {
        let absoluteX = windowBounds.origin.x + x
        let absoluteY = windowBounds.origin.y + y
        
        let eventType: CGEventType = mouseDown ? .leftMouseDown : .leftMouseUp
        
        if let event = CGEvent(
            mouseEventSource: nil,
            mouseType: eventType,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        ) {
            if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                event.postToPid(windowInfo.processID)
            }
        }
    }
    
    private func sendDragEvent(x: CGFloat, y: CGFloat, in windowBounds: CGRect) {
        let absoluteX = windowBounds.origin.x + x
        let absoluteY = windowBounds.origin.y + y
        
        if let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDragged,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        ) {
            if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                event.postToPid(windowInfo.processID)
            }
        }
    }
}

// MARK: - Preview

struct TouchpadView_Previews: PreviewProvider {
    static var previews: some View {
        TouchpadView(automation: iPhoneAutomation(), isExpanded: .constant(true))
    }
}