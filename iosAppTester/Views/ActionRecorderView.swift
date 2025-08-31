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
                        Text("Click and interact with the iPhone Mirroring window...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recorder.recordings, id: \.id) { recording in
                                RecordingRow(
                                    recording: recording,
                                    onReplay: { replayRecording(recording) },
                                    onDelete: { recorder.deleteRecording(recording) }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
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
    
    private func replayRecording(_ recording: ActionRecorder.Recording) {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot replay - window not found")
            return
        }
        
        Task {
            await recorder.replay(recording, in: windowBounds)
        }
    }
}

struct RecordingRow: View {
    let recording: ActionRecorder.Recording
    let onReplay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recording.name)
                    .font(.system(.body, design: .rounded))
                
                HStack {
                    Text("\(recording.actions.count) actions")
                    Text("•")
                    Text(recording.recordedAt, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onReplay) {
                Image(systemName: "play.circle")
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .foregroundColor(.red)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}