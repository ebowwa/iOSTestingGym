//
//  ScenariosView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI

struct ScenariosView: View {
    @ObservedObject var scenarioManager: TestScenarioManager
    @State private var showingAddScenario = false
    @State private var selectedScenario: TestScenario?
    
    var body: some View {
        NavigationView {
            List {
                Section("Default Scenarios") {
                    ForEach(scenarioManager.scenarios) { scenario in
                        ScenarioRowView(
                            scenario: scenario,
                            isEnabled: scenario.isEnabled,
                            onToggle: { scenarioManager.toggleScenario(scenario) },
                            onEdit: { selectedScenario = scenario }
                        )
                    }
                }
                
                if !scenarioManager.customScenarios.isEmpty {
                    Section("Custom Scenarios") {
                        ForEach(scenarioManager.customScenarios) { scenario in
                            ScenarioRowView(
                                scenario: scenario,
                                isEnabled: scenario.isEnabled,
                                onToggle: { scenarioManager.toggleScenario(scenario) },
                                onEdit: { selectedScenario = scenario }
                            )
                        }
                        .onDelete { indices in
                            for index in indices {
                                let scenario = scenarioManager.customScenarios[index]
                                scenarioManager.removeScenario(scenario)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Test Scenarios")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddScenario = true }) {
                        Label("Add Scenario", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddScenario) {
                AddScenarioView(scenarioManager: scenarioManager)
            }
            .sheet(item: $selectedScenario) { scenario in
                ScenarioDetailView(scenario: scenario, scenarioManager: scenarioManager)
            }
        }
    }
}

struct ScenarioRowView: View {
    let scenario: TestScenario
    let isEnabled: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(CheckboxToggleStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.name)
                    .font(.headline)
                Text(scenario.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Label(scenario.deviceType.rawValue, systemImage: deviceIcon(for: scenario.deviceType))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text("\(scenario.delayBeforeCapture, specifier: "%.1f")s delay")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deviceIcon(for deviceType: DeviceType) -> String {
        switch deviceType {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "macbook"
        case .appleWatch: return "applewatch"
        case .appleTV: return "appletv"
        case .visionPro: return "visionpro"
        }
    }
}

struct AddScenarioView: View {
    @ObservedObject var scenarioManager: TestScenarioManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedDevice = DeviceType.iPhone
    @State private var delay: Double = 1.5
    
    var body: some View {
        SheetView(
            title: "New Scenario",
            width: 500,
            height: 400,
            onCancel: { dismiss() },
            onConfirm: {
                let scenario = TestScenario(
                    name: name,
                    description: description,
                    deviceType: selectedDevice,
                    delayBeforeCapture: delay,
                    actions: []
                )
                scenarioManager.addScenario(scenario)
                dismiss()
            },
            confirmLabel: "Add",
            confirmDisabled: name.isEmpty
        ) {
            Form {
                Section("Scenario Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Configuration") {
                    Picker("Device Type", selection: $selectedDevice) {
                        ForEach(DeviceType.allCases, id: \.self) { device in
                            Text(device.rawValue).tag(device)
                        }
                    }
                    
                    HStack {
                        Text("Capture Delay")
                        Slider(value: $delay, in: 0.5...5.0, step: 0.5)
                        Text("\(delay, specifier: "%.1f")s")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}

struct ScenarioDetailView: View {
    @State var scenario: TestScenario
    @ObservedObject var scenarioManager: TestScenarioManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        SheetView(
            title: "Edit Scenario",
            width: 500,
            height: 500,
            onCancel: { dismiss() },
            onConfirm: {
                scenarioManager.updateScenario(scenario)
                dismiss()
            },
            confirmLabel: "Save"
        ) {
            Form {
                Section("Scenario Details") {
                    TextField("Name", text: $scenario.name)
                    TextField("Description", text: $scenario.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Configuration") {
                    Picker("Device Type", selection: $scenario.deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { device in
                            Text(device.rawValue).tag(device)
                        }
                    }
                    
                    HStack {
                        Text("Capture Delay")
                        Slider(value: $scenario.delayBeforeCapture, in: 0.5...5.0, step: 0.5)
                        Text("\(scenario.delayBeforeCapture, specifier: "%.1f")s")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
                
                Section("Test Actions") {
                    if scenario.actions.isEmpty {
                        Text("No actions configured")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(scenario.actions) { action in
                            HStack {
                                Image(systemName: actionIcon(for: action.type))
                                Text(action.type.rawValue)
                                if let value = action.value {
                                    Text("- \(value)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
    
    private func actionIcon(for type: TestAction.ActionType) -> String {
        switch type {
        case .tap: return "hand.tap"
        case .swipe: return "hand.draw"
        case .typeText: return "keyboard"
        case .wait: return "clock"
        case .scroll: return "arrow.up.and.down"
        case .press: return "hand.point.up.left"
        case .pinch: return "arrow.up.left.and.arrow.down.right"
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .secondary)
                .imageScale(.large)
        }
        .buttonStyle(.plain)
    }
}