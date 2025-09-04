//
//  QuickActionsView.swift
//  iosAppTester
//
//  Composable view for displaying quick actions
//

import SwiftUI

struct QuickActionsView: View {
    @ObservedObject var automation: iPhoneAutomation
    @ObservedObject var screenshotManager: ScreenshotManager
    @StateObject private var focusManager = AppFocusManager.shared
    @Binding var isExpanded: Bool
    
    private var context: QuickActionContext {
        DefaultQuickActionContext(
            automation: automation,
            screenshotManager: screenshotManager,
            focusManager: focusManager
        )
    }
    
    private var actions: [QuickAction] {
        [
            FocusWindowAction(context: context),
            HomeButtonAction(context: context),
            AppSwitcherOpenerAction(context: context),
            AppSwitcherCloserAction(context: context),
            ScreenshotAction(context: context)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(actions.indices, id: \.self) { index in
                QuickActionButton(action: actions[index])
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionButton: View {
    let action: QuickAction
    
    var body: some View {
        Button(action: action.execute) {
            Label(action.name, systemImage: action.icon)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(!action.isEnabled)
        .buttonStyle(QuickActionButtonStyle())
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? 
                          Color.accentColor.opacity(0.2) : 
                          Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}