//
//  EmbeddedScenariosView.swift
//  iosAppTester
//
//  A simplified version of ScenariosView for embedding in other views
//

import SwiftUI

struct EmbeddedScenariosView: View {
    @ObservedObject var scenarioManager: TestScenarioManager
    @State private var showingAddScenario = false
    @State private var selectedScenario: TestScenario?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Manage Scenarios")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { 
                    showingAddScenario = true 
                }) {
                    Label("Add", systemImage: "plus.circle")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
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
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingAddScenario) {
            AddScenarioView(scenarioManager: scenarioManager)
        }
        .sheet(item: $selectedScenario) { scenario in
            ScenarioDetailView(scenario: scenario, scenarioManager: scenarioManager)
        }
    }
}