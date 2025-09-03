//
//  ActionRecorderView.swift
//  iosAppTester
//
//  View for recording and replaying user actions
//

import SwiftUI

struct ActionRecorderView: View {
    @ObservedObject var automation: iPhoneAutomation
    @StateObject private var recorder = ActionRecorder()
    @State private var recordingName = ""
    @State private var showNameAlert = false
    @State private var isReplaying = false
    @State private var replayProgress: Double = 0
    @State private var currentReplayAction: String = ""
    @State private var selectedRecording: ActionRecorder.Recording? = nil
    @State private var showRecordingDetails = false
    @State private var showAllAnalytics = false
    @State private var replayStyle: ActionRecorder.ReplayStyle = .human
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Recording Controls
            GroupBox("Record Actions") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Record your interactions with iPhone Mirroring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if recorder.isRecording {
                            Button(action: stopRecording) {
                                Label("Stop Recording", systemImage: "stop.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 2)
                                    .opacity(0.8)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)
                            )
                            
                            Text("\(recorder.currentActions.count) actions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Button(action: startRecording) {
                                Label("Start Recording", systemImage: "record.circle")
                            }
                            .disabled(!automation.isConnected)
                        }
                    }
                    
                    if recorder.isRecording {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .opacity(0.8)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recorder.isRecording)
                                
                                Text("Recording... Click and interact with iPhone Mirroring")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            if !recorder.lastCapturedEvent.isEmpty {
                                Text("Last: \(recorder.lastCapturedEvent)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // Show recent actions
                            if !recorder.currentActions.isEmpty {
                                Text("Recent actions:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                ForEach(Array(recorder.currentActions.suffix(3).enumerated()), id: \.offset) { _, action in
                                    Text("• \(action.description)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            
            // Visual replay indicator
            if isReplaying {
                GroupBox {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isReplaying)
                            
                            Text("Replaying...")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        
                        if !currentReplayAction.isEmpty {
                            Text(currentReplayAction)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        ProgressView(value: replayProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                    .padding(5)
                }
                .background(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 2)
                        .opacity(0.6)
                )
            }
            
            // Saved Recordings
            GroupBox("Saved Recordings") {
                if recorder.recordings.isEmpty {
                    Text("No recordings yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        // Replay Style Selector
                        HStack {
                            Text("Replay Mode:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $replayStyle) {
                                ForEach(ActionRecorder.ReplayStyle.allCases, id: \.self) { style in
                                    Label(style.rawValue, systemImage: style.icon)
                                        .tag(style)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 180)
                            
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        
                        // Analytics button for all recordings
                        if recorder.recordings.count > 1 {
                            Button(action: { showAllAnalytics = true }) {
                                Label("Analyze All Recordings", systemImage: "chart.line.uptrend.xyaxis")
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isReplaying || recorder.isRecording)
                            
                            Divider()
                        }
                        
                        // Export button for iOS
                        if !recorder.recordings.isEmpty {
                            Button(action: exportRecordings) {
                                Label("Export for iOS App", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isReplaying || recorder.isRecording)
                            
                            Divider()
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                            ForEach(recorder.recordings, id: \.id) { recording in
                                RecordingRow(
                                    recording: recording,
                                    recorder: recorder,
                                    onReplay: { replayRecording(recording) },
                                    onDelete: { recorder.deleteRecording(recording) },
                                    onShowDetails: { 
                                        selectedRecording = recording
                                        showRecordingDetails = true
                                    },
                                    isDisabled: isReplaying || recorder.isRecording
                                )
                            }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            // Instructions
            GroupBox("How to Use") {
                VStack(alignment: .leading, spacing: 5) {
                    Label("1. Click 'Start Recording'", systemImage: "1.circle")
                    Label("2. Perform actions on iPhone (hover, click Home, etc.)", systemImage: "2.circle")
                    Label("3. Click 'Stop Recording' and name it", systemImage: "3.circle")
                    Label("4. Replay anytime with one click", systemImage: "4.circle")
                }
                .font(.caption)
            }
        }
        .padding()
        .onAppear {
            recorder.loadRecordings()
        }
        .alert("Name Your Recording", isPresented: $showNameAlert) {
            TextField("Recording name", text: $recordingName)
            Button("Save") {
                recorder.stopRecording(name: recordingName)
                recordingName = ""
            }
            Button("Cancel") {
                recorder.stopRecording(name: nil)
                recordingName = ""
            }
        }
        .sheet(isPresented: $showRecordingDetails) {
            if let recording = selectedRecording {
                RecordingDetailsView(recording: recording, recorder: recorder)
            }
        }
        .sheet(isPresented: $showAllAnalytics) {
            RecordingAnalyticsView(recording: nil, recordings: recorder.recordings)
        }
    }
    
    private func startRecording() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot start recording - window not found")
            return
        }
        
        recorder.startRecording(windowBounds: windowBounds)
    }
    
    private func stopRecording() {
        showNameAlert = true
    }
    
    private func exportRecordings() {
        RecordingExporter.exportRecordings(recorder.recordings)
    }
    
    private func replayRecording(_ recording: ActionRecorder.Recording) {
        guard let initialWindowBounds = automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot replay - window not found")
            return
        }
        
        Task {
            isReplaying = true
            replayProgress = 0
            currentReplayAction = "Starting replay..."
            
            // Use the smart replay method that tracks window position with selected style
            await recorder.replay(recording, in: initialWindowBounds, style: replayStyle) { current, total, description in
                Task { @MainActor in
                    replayProgress = Double(current) / Double(total)
                    currentReplayAction = description
                }
            }
            
            await MainActor.run {
                currentReplayAction = "Replay complete!"
                replayProgress = 1.0
            }
            
            // Keep the completion message visible briefly
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isReplaying = false
                replayProgress = 0
                currentReplayAction = ""
            }
        }
    }
}

struct RecordingRow: View {
    let recording: ActionRecorder.Recording
    @ObservedObject var recorder: ActionRecorder
    let onReplay: () -> Void
    let onDelete: () -> Void
    let onShowDetails: () -> Void
    var isDisabled: Bool = false
    @State private var isEditingName = false
    @State private var editedName: String = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if isEditingName {
                    TextField("Recording name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                        .onSubmit {
                            saveNameChange()
                        }
                } else {
                    HStack {
                        Text(recording.name)
                            .font(.system(.body, design: .rounded))
                        Button(action: {
                            editedName = recording.name
                            isEditingName = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDisabled ? 0 : 1)
                    }
                }
                
                HStack {
                    Text("\(recording.actions.count) actions")
                    Text("•")
                    Text(recording.recordedAt, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onShowDetails) {
                Image(systemName: "info.circle")
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            
            Button(action: onReplay) {
                Image(systemName: "play.circle")
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .foregroundColor(.red)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .onTapGesture {
            if !isDisabled && !isEditingName {
                onShowDetails()
            }
        }
    }
    
    private func saveNameChange() {
        if !editedName.isEmpty && editedName != recording.name {
            // Find and update the recording
            if let index = recorder.recordings.firstIndex(where: { $0.id == recording.id }) {
                recorder.recordings[index].name = editedName
                recorder.saveRecordings()
            }
        }
        isEditingName = false
    }
}