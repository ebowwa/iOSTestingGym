//
//  ToolbarCalibrationView.swift
//  iosAppTester
//
//  View for calibrating iPhone Mirroring toolbar button positions
//

import SwiftUI

struct ToolbarCalibrationView: View {
    @ObservedObject var automation: iPhoneAutomation
    @State private var isCalibrating = false
    @State private var calibrationResult = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Toolbar Calibration")
                .font(.headline)
            
            Text("This will capture the toolbar and analyze button positions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Calibrate Toolbar") {
                    calibrateToolbar()
                }
                .disabled(!automation.isConnected || isCalibrating)
                
                if isCalibrating {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            
            if !calibrationResult.isEmpty {
                Text(calibrationResult)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
    }
    
    private func calibrateToolbar() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else {
            calibrationResult = "❌ iPhone Mirroring window not found"
            return
        }
        
        isCalibrating = true
        calibrationResult = "🔄 Calibrating..."
        
        Task {
            await ToolbarDetector.calibrateButtons(
                windowBounds: windowBounds,
                automation: automation
            )
            
            await MainActor.run {
                isCalibrating = false
                calibrationResult = "✅ Calibration complete - check Desktop for screenshot"
            }
        }
    }
}