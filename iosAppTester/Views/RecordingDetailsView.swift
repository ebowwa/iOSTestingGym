//
//  RecordingDetailsView.swift
//  iosAppTester
//
//  Shows detailed information about a recording for debugging
//

import SwiftUI

struct RecordingDetailsView: View {
    @State var recording: ActionRecorder.Recording
    @ObservedObject var recorder: ActionRecorder
    @Environment(\.dismiss) var dismiss
    @State private var editedActions: [ActionRecorder.RecordedAction] = []
    @State private var actionNotes: [Int: String] = [:]
    @State private var removedIndices: Set<Int> = []
    @State private var playingActionIndex: Int? = nil
    @State private var hasChanges = false
    @State private var editedName: String = ""
    @State private var isEditingName = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text("Recording Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recording Info
                    GroupBox("Recording Information") {
                        VStack(alignment: .leading, spacing: 10) {
                            // Editable name field
                            HStack {
                                Text("Name:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if isEditingName {
                                    TextField("Recording name", text: $editedName)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.caption)
                                        .frame(maxWidth: 200)
                                        .onSubmit {
                                            if editedName != recording.name && !editedName.isEmpty {
                                                hasChanges = true
                                            }
                                            isEditingName = false
                                        }
                                    Button("Done") {
                                        if editedName != recording.name && !editedName.isEmpty {
                                            hasChanges = true
                                        }
                                        isEditingName = false
                                    }
                                    .font(.caption)
                                } else {
                                    Text(editedName.isEmpty ? recording.name : editedName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Button(action: {
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            InfoRow(label: "Recorded At", value: recording.recordedAt.formatted())
                            InfoRow(label: "Total Actions", value: "\(recording.actions.count)")
                            InfoRow(label: "Duration", value: String(format: "%.1f seconds", recording.duration))
                            InfoRow(label: "Recording ID", value: recording.id.uuidString)
                        }
                    }
                    
                    // Window Bounds
                    GroupBox("Window Bounds (at recording time)") {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(label: "Origin X", value: String(format: "%.1f", recording.windowBounds.origin.x))
                            InfoRow(label: "Origin Y", value: String(format: "%.1f", recording.windowBounds.origin.y))
                            InfoRow(label: "Width", value: String(format: "%.1f", recording.windowBounds.width))
                            InfoRow(label: "Height", value: String(format: "%.1f", recording.windowBounds.height))
                            
                            Text("Note: Origin Y is in top-left coordinate system from CGWindowListCopyWindowInfo")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Actions List with Raw Data
                    GroupBox("Recorded Actions (Raw Data)") {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(Array(recording.actions.enumerated()), id: \.offset) { index, action in
                                if !removedIndices.contains(index) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text("Action \(index + 1)")
                                                .font(.headline)
                                                .foregroundColor(removedIndices.contains(index) ? .red : .primary)
                                                .strikethrough(removedIndices.contains(index))
                                            
                                            Spacer()
                                            
                                            // Action controls
                                            HStack(spacing: 8) {
                                                // Play individual action
                                                Button(action: {
                                                    playAction(action, at: index)
                                                }) {
                                                    Image(systemName: playingActionIndex == index ? "stop.circle.fill" : "play.circle")
                                                        .foregroundColor(playingActionIndex == index ? .orange : .blue)
                                                }
                                                .buttonStyle(.plain)
                                                .help("Play this action")
                                                
                                                // Remove action
                                                Button(action: {
                                                    toggleRemoval(at: index)
                                                }) {
                                                    Image(systemName: removedIndices.contains(index) ? "arrow.uturn.backward.circle" : "minus.circle")
                                                        .foregroundColor(removedIndices.contains(index) ? .green : .red)
                                                }
                                                .buttonStyle(.plain)
                                                .help(removedIndices.contains(index) ? "Restore action" : "Remove action")
                                                
                                                Text(actionType(for: action))
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text(action.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        // Show raw coordinate data
                                        actionDetails(for: action)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                        
                                        // Notes/annotation field
                                        HStack {
                                            Text("Notes:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("Add notes for this action...", text: Binding(
                                                get: { actionNotes[index] ?? recording.annotations[index] ?? "" },
                                                set: { 
                                                    actionNotes[index] = $0
                                                    hasChanges = true
                                                }
                                            ))
                                            .textFieldStyle(.roundedBorder)
                                            .font(.caption)
                                        }
                                        
                                        // Show existing annotation if present
                                        if let existingNote = recording.annotations[index], 
                                           !existingNote.isEmpty && actionNotes[index] == nil {
                                            Text("Saved note: \(existingNote)")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                                .italic()
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .opacity(removedIndices.contains(index) ? 0.5 : 1.0)
                                    
                                    if index < recording.actions.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            
                            // Summary of changes
                            if !removedIndices.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Divider()
                                    Text("Changes:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("\(removedIndices.count) action(s) marked for removal")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Bottom toolbar
            if hasChanges {
                HStack {
                    Button("Reset Changes") {
                        removedIndices.removeAll()
                        actionNotes = recording.annotations
                        editedName = recording.name
                        hasChanges = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Update Original") {
                        updateRecording()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save as New") {
                        saveAsNewRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(removedIndices.count == recording.actions.count)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            editedActions = recording.actions
            actionNotes = recording.annotations
            editedName = recording.name
        }
    }
    
    // MARK: - Helper Methods
    
    private func playAction(_ action: ActionRecorder.RecordedAction, at index: Int) {
        if playingActionIndex == index {
            // Stop playing
            playingActionIndex = nil
            return
        }
        
        // Get current window bounds
        guard let windowInfo = WindowDetector.getiPhoneMirroringWindow() else {
            print("❌ Cannot play action - iPhone Mirroring window not found")
            return
        }
        
        playingActionIndex = index
        
        Task {
            await recorder.executeAction(action, in: windowInfo.bounds)
            
            await MainActor.run {
                playingActionIndex = nil
            }
        }
    }
    
    private func toggleRemoval(at index: Int) {
        if removedIndices.contains(index) {
            removedIndices.remove(index)
        } else {
            removedIndices.insert(index)
        }
        hasChanges = true
    }
    
    private func saveAsNewRecording() {
        // Filter out removed actions and adjust annotation indices
        var newActions: [ActionRecorder.RecordedAction] = []
        var newAnnotations: [Int: String] = [:]
        var newIndex = 0
        
        for (oldIndex, action) in recording.actions.enumerated() {
            if !removedIndices.contains(oldIndex) {
                newActions.append(action)
                if let note = actionNotes[oldIndex], !note.isEmpty {
                    newAnnotations[newIndex] = note
                }
                newIndex += 1
            }
        }
        
        // Create new recording with filtered actions
        let newRecordingName = editedName.isEmpty ? recording.name : editedName
        let newRecording = ActionRecorder.Recording(
            name: "\(newRecordingName) (Copy)",
            windowBounds: recording.windowBounds,
            actions: newActions,
            recordedAt: Date(),
            annotations: newAnnotations
        )
        
        // Save the new recording
        recorder.recordings.append(newRecording)
        recorder.saveRecordings()
        dismiss()
    }
    
    private func updateRecording() {
        // Filter out removed actions and adjust annotation indices
        var newActions: [ActionRecorder.RecordedAction] = []
        var newAnnotations: [Int: String] = [:]
        var newIndex = 0
        
        for (oldIndex, action) in recording.actions.enumerated() {
            if !removedIndices.contains(oldIndex) {
                newActions.append(action)
                if let note = actionNotes[oldIndex], !note.isEmpty {
                    newAnnotations[newIndex] = note
                }
                newIndex += 1
            }
        }
        
        // Update the recording
        recording.name = editedName.isEmpty ? recording.name : editedName
        recording.actions = newActions
        recording.annotations = newAnnotations
        
        // Save the updated recording
        if let index = recorder.recordings.firstIndex(where: { $0.id == recording.id }) {
            recorder.recordings[index] = recording
            recorder.saveRecordings()
        }
        dismiss()
    }
    
    func actionType(for action: ActionRecorder.RecordedAction) -> String {
        switch action {
        case .mouseMove: return "Move"
        case .mouseClick: return "Click"
        case .mouseDown: return "Down"
        case .mouseUp: return "Up"
        case .mouseDrag: return "Drag"
        case .keyPress: return "Key"
        case .wait: return "Wait"
        }
    }
    
    func actionDetails(for action: ActionRecorder.RecordedAction) -> Text {
        switch action {
        case .mouseMove(let x, let y, let relX, let relY):
            return Text("""
                Absolute: (\(Int(x)), \(Int(y)))
                Relative: (\(String(format: "%.3f", relX)), \(String(format: "%.3f", relY)))
                Percentage: (\(Int(relX*100))%, \(Int(relY*100))%)
                """)
            
        case .mouseClick(let x, let y, let relX, let relY, let count):
            return Text("""
                Absolute: (\(Int(x)), \(Int(y)))
                Relative: (\(String(format: "%.3f", relX)), \(String(format: "%.3f", relY)))
                Percentage: (\(Int(relX*100))%, \(Int(relY*100))%)
                Click Count: \(count)
                """)
            
        case .mouseDown(let x, let y, let relX, let relY):
            return Text("""
                Absolute: (\(Int(x)), \(Int(y)))
                Relative: (\(String(format: "%.3f", relX)), \(String(format: "%.3f", relY)))
                Percentage: (\(Int(relX*100))%, \(Int(relY*100))%)
                """)
            
        case .mouseUp(let x, let y, let relX, let relY):
            return Text("""
                Absolute: (\(Int(x)), \(Int(y)))
                Relative: (\(String(format: "%.3f", relX)), \(String(format: "%.3f", relY)))
                Percentage: (\(Int(relX*100))%, \(Int(relY*100))%)
                """)
            
        case .mouseDrag(let fromX, let fromY, let toX, let toY, 
                       let fromRelX, let fromRelY, let toRelX, let toRelY):
            return Text("""
                From Absolute: (\(Int(fromX)), \(Int(fromY)))
                From Relative: (\(String(format: "%.3f", fromRelX)), \(String(format: "%.3f", fromRelY)))
                To Absolute: (\(Int(toX)), \(Int(toY)))
                To Relative: (\(String(format: "%.3f", toRelX)), \(String(format: "%.3f", toRelY)))
                """)
            
        case .keyPress(let keyCode, let modifiers):
            return Text("""
                Key Code: \(keyCode)
                Modifiers: \(modifiers)
                """)
            
        case .wait(let seconds):
            return Text("Duration: \(String(format: "%.3f", seconds)) seconds")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}