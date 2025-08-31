//
//  AppFocusManager.swift
//  iosAppTester
//
//  Manages app focus state to prevent background operations
//

import SwiftUI
import AppKit

class AppFocusManager: ObservableObject {
    @Published var isAppActive = false
    @Published var isWindowKey = false
    @Published var canAcceptInput = false
    
    private var observers: [Any] = []
    
    static let shared = AppFocusManager()
    
    private init() {
        setupObservers()
        updateFocusState()
    }
    
    private func setupObservers() {
        // Observe app activation/deactivation
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.handleAppBecameActive()
            }
        )
        
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.handleAppResignedActive()
            }
        )
        
        // Observe window focus changes
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.handleWindowBecameKey()
            }
        )
        
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.handleWindowResignedKey()
            }
        )
    }
    
    private func handleAppBecameActive() {
        isAppActive = true
        updateFocusState()
        print("🎯 App became active")
    }
    
    private func handleAppResignedActive() {
        isAppActive = false
        updateFocusState()
        print("😴 App resigned active - disabling controls")
    }
    
    private func handleWindowBecameKey() {
        isWindowKey = true
        updateFocusState()
        print("🪟 Window became key")
    }
    
    private func handleWindowResignedKey() {
        isWindowKey = false
        updateFocusState()
        print("🪟 Window resigned key - disabling controls")
    }
    
    private func updateFocusState() {
        // Only accept input when app is active AND window is key
        canAcceptInput = isAppActive && isWindowKey
        
        if !canAcceptInput {
            print("⚠️ Controls disabled - app not in focus")
        }
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}