//
//  TestScenario.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import Foundation

struct TestScenario: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String
    var deviceType: DeviceType
    var delayBeforeCapture: TimeInterval
    var actions: [TestAction]
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, description: String, deviceType: DeviceType, delayBeforeCapture: TimeInterval, actions: [TestAction], isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.deviceType = deviceType
        self.delayBeforeCapture = delayBeforeCapture
        self.actions = actions
        self.isEnabled = isEnabled
    }
    
    static var defaultScenarios: [TestScenario] {
        [
            TestScenario(
                name: "Instant Capture",
                description: "Capture immediately",
                deviceType: .mac,
                delayBeforeCapture: 0.5,
                actions: [],
                isEnabled: true
            ),
            TestScenario(
                name: "After 2 Seconds",
                description: "Capture after 2 second delay",
                deviceType: .mac,
                delayBeforeCapture: 2.0,
                actions: [],
                isEnabled: false
            ),
            TestScenario(
                name: "After 5 Seconds", 
                description: "Capture after 5 second delay (for interactions)",
                deviceType: .mac,
                delayBeforeCapture: 5.0,
                actions: [],
                isEnabled: false
            )
        ]
    }
    
    static func customScenario(name: String, deviceType: DeviceType) -> TestScenario {
        TestScenario(
            name: name,
            description: "Custom test scenario",
            deviceType: deviceType,
            delayBeforeCapture: 1.5,
            actions: []
        )
    }
}

struct TestAction: Identifiable, Hashable, Codable {
    let id: UUID
    var type: ActionType
    var target: String
    var value: String?
    var delay: TimeInterval
    
    init(id: UUID = UUID(), type: ActionType, target: String, value: String? = nil, delay: TimeInterval) {
        self.id = id
        self.type = type
        self.target = target
        self.value = value
        self.delay = delay
    }
    
    enum ActionType: String, CaseIterable, Codable {
        case tap = "Tap"
        case swipe = "Swipe"
        case typeText = "Type Text"
        case wait = "Wait"
        case scroll = "Scroll"
        case press = "Press"
        case pinch = "Pinch"
    }
}

class TestScenarioManager: ObservableObject {
    @Published var scenarios: [TestScenario] = TestScenario.defaultScenarios
    @Published var customScenarios: [TestScenario] = []
    
    init() {
        loadCustomScenarios()
    }
    
    func addScenario(_ scenario: TestScenario) {
        customScenarios.append(scenario)
        saveCustomScenarios()
    }
    
    func removeScenario(_ scenario: TestScenario) {
        customScenarios.removeAll { $0.id == scenario.id }
        saveCustomScenarios()
    }
    
    func updateScenario(_ scenario: TestScenario) {
        if let index = customScenarios.firstIndex(where: { $0.id == scenario.id }) {
            customScenarios[index] = scenario
            saveCustomScenarios()
        }
    }
    
    func toggleScenario(_ scenario: TestScenario) {
        if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
            scenarios[index].isEnabled.toggle()
        } else if let index = customScenarios.firstIndex(where: { $0.id == scenario.id }) {
            customScenarios[index].isEnabled.toggle()
            saveCustomScenarios()
        }
    }
    
    var allEnabledScenarios: [TestScenario] {
        (scenarios + customScenarios).filter { $0.isEnabled }
    }
    
    private func saveCustomScenarios() {
        if let encoded = try? JSONEncoder().encode(customScenarios) {
            UserDefaults.standard.set(encoded, forKey: "CustomTestScenarios")
        }
    }
    
    private func loadCustomScenarios() {
        if let data = UserDefaults.standard.data(forKey: "CustomTestScenarios"),
           let decoded = try? JSONDecoder().decode([TestScenario].self, from: data) {
            customScenarios = decoded
        }
    }
}