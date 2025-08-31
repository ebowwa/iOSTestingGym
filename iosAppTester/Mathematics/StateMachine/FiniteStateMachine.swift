//
//  FiniteStateMachine.swift
//  Control Theory Implementation
//
//  Single Responsibility: Generic finite state machine for control flow
//

import Foundation

protocol StateMachineState: Equatable {
    associatedtype Input
    associatedtype Output
    
    func transition(with input: Input) -> Self
    func output(for input: Input) -> Output?
}

class FiniteStateMachine<S: StateMachineState> {
    private(set) var currentState: S
    private var stateHistory: [S] = []
    private let maxHistorySize: Int
    
    init(initialState: S, maxHistorySize: Int = 100) {
        self.currentState = initialState
        self.maxHistorySize = maxHistorySize
        self.stateHistory.append(initialState)
    }
    
    // Process input and transition
    @discardableResult
    func process(_ input: S.Input) -> S.Output? {
        let output = currentState.output(for: input)
        let newState = currentState.transition(with: input)
        
        if newState != currentState {
            currentState = newState
            recordState(newState)
        }
        
        return output
    }
    
    // Record state in history
    private func recordState(_ state: S) {
        stateHistory.append(state)
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
        }
    }
    
    // Get state history
    func getHistory() -> [S] {
        stateHistory
    }
    
    // Reset to initial state
    func reset(to state: S) {
        currentState = state
        stateHistory = [state]
    }
}

// Touchpad specific state
enum TouchpadState: StateMachineState {
    case idle
    case holding(startTime: Date)
    case dragging(startPoint: Vector2D)
    case clicking
    
    enum Input {
        case pressStarted
        case pressMoved(Vector2D)
        case pressEnded(Vector2D)
        case timeout
    }
    
    enum Output {
        case startHold
        case moveCursor(Vector2D)
        case performClick(Vector2D)
        case reset
    }
    
    func transition(with input: Input) -> TouchpadState {
        switch (self, input) {
        case (.idle, .pressStarted):
            return .holding(startTime: Date())
        case (.holding, .pressMoved(let point)):
            return .dragging(startPoint: point)
        case (.holding, .pressEnded):
            return .clicking
        case (.dragging, .pressEnded):
            return .idle
        case (.clicking, _):
            return .idle
        case (_, .timeout):
            return .idle
        default:
            return self
        }
    }
    
    func output(for input: Input) -> Output? {
        switch (self, input) {
        case (.holding, .pressStarted):
            return .startHold
        case (.dragging, .pressMoved(let point)):
            return .moveCursor(point)
        case (.clicking, .pressEnded(let point)):
            return .performClick(point)
        case (_, .timeout):
            return .reset
        default:
            return nil
        }
    }
}