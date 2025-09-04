//
//  SheetView.swift
//  iosAppTester
//
//  A reusable sheet presentation component that avoids NavigationView issues
//  when presented from Form contexts (especially in Settings tabs).
//

import SwiftUI

/// A standardized sheet view container that provides proper layout and button handling
/// without using NavigationView, which causes sizing issues in sheet presentations.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showingSheet) {
///     SheetView(
///         title: "My Sheet",
///         width: 500,
///         height: 400,
///         onCancel: { showingSheet = false },
///         onConfirm: { 
///             saveData()
///             showingSheet = false 
///         },
///         confirmLabel: "Save",
///         confirmDisabled: formInvalid
///     ) {
///         // Your form content here
///         Form {
///             TextField("Name", text: $name)
///         }
///     }
/// }
/// ```
struct SheetView<Content: View>: View {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let onCancel: () -> Void
    let onConfirm: (() -> Void)?
    let confirmLabel: String
    let confirmDisabled: Bool
    @ViewBuilder let content: () -> Content
    
    init(
        title: String,
        width: CGFloat = 500,
        height: CGFloat = 400,
        onCancel: @escaping () -> Void,
        onConfirm: (() -> Void)? = nil,
        confirmLabel: String = "OK",
        confirmDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.confirmLabel = confirmLabel
        self.confirmDisabled = confirmDisabled
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main content
            content()
                .frame(maxHeight: .infinity)
            
            // Button bar
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if let onConfirm = onConfirm {
                    Button(confirmLabel, action: onConfirm)
                        .keyboardShortcut(.defaultAction)
                        .disabled(confirmDisabled)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: width, height: height)
    }
}

/// Convenience initializer for simple OK/Cancel dialogs
extension SheetView where Content == EmptyView {
    init(
        title: String,
        message: String,
        width: CGFloat = 400,
        height: CGFloat = 200,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        confirmLabel: String = "OK"
    ) {
        self.init(
            title: title,
            width: width,
            height: height,
            onCancel: onCancel,
            onConfirm: onConfirm,
            confirmLabel: confirmLabel,
            confirmDisabled: false
        ) {
            EmptyView()
        }
    }
}