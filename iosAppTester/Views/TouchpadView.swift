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
    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var lastDragLocation: CGPoint = .zero
    @State private var virtualCursorPosition: CGPoint = CGPoint(x: 186, y: 412) // Start at center of iPhone
    @State private var showTouchIndicator = false
    @State private var touchIndicatorPosition: CGPoint = .zero
    @State private var currentPosition: CGPoint = .zero
    @State private var isMouseDown = false
    
    // Touchpad acts like a laptop trackpad - relative movement
    let touchpadWidth: CGFloat = 250
    let touchpadHeight: CGFloat = 180
    let sensitivity: CGFloat = 2.0 // Movement multiplier
    
    var body: some View {
        VStack(spacing: 20) {
            // Touchpad Area
            ZStack {
                // Background - simple trackpad style
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(automation.isConnected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Touch indicator
                if showTouchIndicator {
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 30, height: 30)
                        .position(touchIndicatorPosition)
                        .animation(.easeOut(duration: 0.1), value: touchIndicatorPosition)
                }
                
                // Current position indicator
                if isDragging {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .position(currentPosition)
                }
                
                // Instructions when not connected
                if !automation.isConnected {
                    Text("Connect iPhone First")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: touchpadWidth, height: touchpadHeight)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    handleHover(at: location)
                case .ended:
                    showTouchIndicator = false
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
            
            // Control buttons
            HStack(spacing: 20) {
                // Quick tap in center
                Button(action: {
                    tapCenter()
                }) {
                    Label("Tap Center", systemImage: "hand.tap")
                }
                .disabled(!automation.isConnected)
                
                // Home button
                Button(action: {
                    _ = automation.pressHome()
                }) {
                    Label("Home", systemImage: "house")
                }
                .disabled(!automation.isConnected)
                
                // App Switcher
                Button(action: {
                    _ = automation.openAppSwitcher()
                }) {
                    Label("Switcher", systemImage: "square.stack.3d.up")
                }
                .disabled(!automation.isConnected)
            }
            .buttonStyle(.bordered)
            
            // Coordinate display - show virtual cursor position
            HStack {
                Text("Cursor: X: \(Int(virtualCursorPosition.x)) Y: \(Int(virtualCursorPosition.y))")
                Spacer()
                if isDragging {
                    Text("Moving")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            
            // Compact instructions
            HStack(spacing: 15) {
                Label("Drag to move cursor", systemImage: "cursorarrow.motionlines")
                Label("Tap to click", systemImage: "hand.tap")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Gesture Handlers
    
    private func handleHover(at location: CGPoint) {
        guard automation.isConnected else { return }
        
        // For relative movement, hover shows where the touch would start
        showTouchIndicator = true
        touchIndicatorPosition = location
        currentPosition = location
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard automation.isConnected else { return }
        
        if !isDragging {
            // Start of drag - record starting position
            isDragging = true
            dragStart = value.startLocation
            lastDragLocation = value.startLocation
            currentPosition = value.location
        } else {
            // Calculate relative movement from last position
            let deltaX = (value.location.x - lastDragLocation.x) * sensitivity
            let deltaY = (value.location.y - lastDragLocation.y) * sensitivity
            
            // Update virtual cursor position with bounds checking
            virtualCursorPosition.x = min(372, max(0, virtualCursorPosition.x + deltaX))
            virtualCursorPosition.y = min(824, max(0, virtualCursorPosition.y + deltaY))
            
            lastDragLocation = value.location
            currentPosition = value.location
            
            // Move the actual cursor on the iPhone screen
            if let windowBounds = automation.getiPhoneMirroringWindow() {
                let absoluteX = windowBounds.origin.x + virtualCursorPosition.x
                let absoluteY = windowBounds.origin.y + virtualCursorPosition.y
                
                // Move cursor to new position
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
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard automation.isConnected else { return }
        
        let distance = sqrt(pow(value.location.x - dragStart.x, 2) + pow(value.location.y - dragStart.y, 2))
        
        if distance < 5 {
            // It's a tap - click at current virtual cursor position
            if let windowBounds = automation.getiPhoneMirroringWindow() {
                automation.tapAt(x: virtualCursorPosition.x, y: virtualCursorPosition.y, in: windowBounds)
            }
        } else {
            // Just a cursor movement, no action needed
            automation.log("📱 Moved cursor via touchpad", level: .info)
        }
        
        isDragging = false
        isMouseDown = false
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
    
    private func tapCenter() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        // Reset virtual cursor to center and tap
        virtualCursorPosition = CGPoint(x: 186, y: 412)
        automation.tapAt(x: 186, y: 412, in: windowBounds) // Center of iPhone screen
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
        TouchpadView(automation: iPhoneAutomation())
    }
}