//
//  RecordingAnalyticsView.swift
//  iosAppTester
//
//  View for displaying recording analytics and insights
//

import SwiftUI
import Charts
import AppKit
import UniformTypeIdentifiers

struct RecordingAnalyticsView: View {
    let recording: ActionRecorder.Recording?
    let recordings: [ActionRecorder.Recording]
    @State private var insights: RecordingAnalytics.RecordingInsights?
    @State private var combinedInsights: RecordingAnalytics.CombinedInsights?
    @State private var selectedTab = 0
    @State private var showingExportSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(recording != nil ? "Recording Analytics" : "All Recordings Analytics")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                if let recording = recording {
                    Text("Analyzing: \(recording.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Analyzing \(recordings.count) recordings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Export buttons
                HStack(spacing: 8) {
                    Button(action: exportToMarkdown) {
                        Label("Export Markdown", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: exportToJSON) {
                        Label("Export JSON", systemImage: "doc.badge.gearshape")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: copyToClipboard) {
                        Label("Copy Report", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            if showingExportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Report copied to clipboard!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Tab Selection
            Picker("Analytics Type", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Patterns").tag(1)
                Text("Heatmap").tag(2)
                Text("Optimization").tag(3)
                if recording == nil {
                    Text("Habits").tag(4)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case 0:
                        overviewTab
                    case 1:
                        patternsTab
                    case 2:
                        heatmapTab
                    case 3:
                        optimizationTab
                    case 4:
                        habitsTab
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 700)
        .onAppear {
            analyzeRecordings()
        }
    }
    
    // MARK: - Overview Tab
    
    @ViewBuilder
    private var overviewTab: some View {
        if let insights = insights {
            GroupBox("Recording Overview") {
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(label: "Total Actions", value: "\(insights.totalActions)")
                    StatRow(label: "Duration", value: formatDuration(insights.duration))
                    StatRow(label: "Actions/Second", value: String(format: "%.2f", insights.actionsPerSecond))
                    
                    Divider()
                    
                    // Wait Time Analysis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wait Time Analysis")
                            .font(.headline)
                        
                        ProgressView(value: insights.waitTimeAnalysis.waitTimePercentage / 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: waitTimeColor(insights.waitTimeAnalysis.waitTimePercentage)))
                        
                        HStack {
                            Text("\(Int(insights.waitTimeAnalysis.waitTimePercentage))% wait time")
                                .font(.caption)
                            Spacer()
                            Text("Total: \(formatDuration(insights.waitTimeAnalysis.totalWaitTime))")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Toolbar Usage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Toolbar Usage")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            ToolbarStatView(
                                icon: "house",
                                count: insights.toolbarUsage.homeButtonClicks,
                                label: "Home"
                            )
                            
                            ToolbarStatView(
                                icon: "square.stack.3d.up",
                                count: insights.toolbarUsage.appSwitcherClicks,
                                label: "Switcher"
                            )
                            
                            ToolbarStatView(
                                icon: "cursorarrow.click",
                                count: insights.toolbarUsage.toolbarClicks,
                                label: "Total Toolbar"
                            )
                        }
                    }
                }
            }
        } else if let combined = combinedInsights {
            GroupBox("Combined Analytics") {
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(label: "Total Recordings", value: "\(combined.totalRecordings)")
                    StatRow(label: "Total Actions", value: "\(combined.totalActions)")
                    StatRow(label: "Avg Duration", value: formatDuration(combined.averageDuration))
                    StatRow(label: "Avg Actions/Recording", value: String(format: "%.1f", combined.userHabits.averageActionsPerRecording))
                }
            }
        }
    }
    
    // MARK: - Patterns Tab
    
    @ViewBuilder
    private var patternsTab: some View {
        GroupBox("Common Patterns") {
            VStack(alignment: .leading, spacing: 12) {
                if let insights = insights {
                    // Most Frequent Actions
                    Text("Most Frequent Actions")
                        .font(.headline)
                    
                    ForEach(insights.mostFrequentActions.prefix(5), id: \.type) { pattern in
                        HStack {
                            Image(systemName: iconForActionType(pattern.type))
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(pattern.type)
                                .font(.system(.body, design: .monospaced))
                            
                            Spacer()
                            
                            Text("\(pattern.frequency)x")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Divider()
                    
                    // Common Workflows
                    Text("Common Workflows")
                        .font(.headline)
                    
                    ForEach(insights.commonWorkflows.prefix(3), id: \.name) { workflow in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(workflow.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(workflow.frequency)x")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(workflow.sequence.joined(separator: " → "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Text("Avg duration: \(formatDuration(workflow.averageDuration))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } else if let combined = combinedInsights {
                    Text("Cross-Recording Patterns")
                        .font(.headline)
                    
                    ForEach(combined.commonPatterns.prefix(5), id: \.name) { pattern in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.name)
                                .font(.subheadline)
                            
                            Text(pattern.sequence.joined(separator: " → "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            HStack {
                                Text("Frequency: \(pattern.frequency)")
                                Text("•")
                                Text("Duration: \(formatDuration(pattern.averageDuration))")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Heatmap Tab
    
    @ViewBuilder
    private var heatmapTab: some View {
        GroupBox("Click Heatmap") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Most clicked areas (relative to window)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Visual heatmap grid
                HeatmapGrid(hotspots: insights?.hotspots ?? [])
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Divider()
                
                // Top hotspots list
                if let hotspots = insights?.hotspots.prefix(5) {
                    Text("Top Click Locations")
                        .font(.headline)
                    
                    ForEach(Array(hotspots.enumerated()), id: \.offset) { _, hotspot in
                        HStack {
                            Circle()
                                .fill(heatmapColor(for: hotspot.frequency))
                                .frame(width: 12, height: 12)
                            
                            Text("(\(Int(hotspot.relativePosition.x * 100))%, \(Int(hotspot.relativePosition.y * 100))%)")
                                .font(.system(.caption, design: .monospaced))
                            
                            Spacer()
                            
                            Text("\(hotspot.frequency) clicks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Optimization Tab
    
    @ViewBuilder
    private var optimizationTab: some View {
        GroupBox("Optimization Opportunities") {
            VStack(alignment: .leading, spacing: 12) {
                if let combined = combinedInsights {
                    if combined.optimizationOpportunities.isEmpty {
                        Text("No optimization opportunities found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(combined.optimizationOpportunities.prefix(5), id: \.description) { suggestion in
                            OptimizationCard(suggestion: suggestion)
                        }
                    }
                } else {
                    // Single recording optimization
                    if let insights = insights {
                        VStack(alignment: .leading, spacing: 8) {
                            if insights.waitTimeAnalysis.waitTimePercentage > 30 {
                                OptimizationCard(suggestion: RecordingAnalytics.OptimizationSuggestion(
                                    type: "High Wait Time",
                                    description: "This recording has \(Int(insights.waitTimeAnalysis.waitTimePercentage))% wait time. Consider reducing delays between actions.",
                                    potentialTimeSaving: insights.waitTimeAnalysis.totalWaitTime * 0.3,
                                    affectedRecordings: [recording?.name ?? "Current"]
                                ))
                            }
                            
                            if insights.actionsPerSecond < 0.5 {
                                OptimizationCard(suggestion: RecordingAnalytics.OptimizationSuggestion(
                                    type: "Slow Execution",
                                    description: "Actions are executing slowly. Consider removing unnecessary waits.",
                                    potentialTimeSaving: insights.duration * 0.2,
                                    affectedRecordings: [recording?.name ?? "Current"]
                                ))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Habits Tab
    
    @ViewBuilder
    private var habitsTab: some View {
        if let combined = combinedInsights {
            GroupBox("User Habits") {
                VStack(alignment: .leading, spacing: 12) {
                    // Preferred Click Areas
                    Text("Preferred Click Areas")
                        .font(.headline)
                    
                    ForEach(combined.userHabits.preferredClickAreas.prefix(3), id: \.frequency) { area in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            
                            Text("Position: (\(Int(area.relativePosition.x * 100))%, \(Int(area.relativePosition.y * 100))%)")
                                .font(.system(.caption, design: .monospaced))
                            
                            Spacer()
                            
                            Text("\(area.frequency) clicks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Common Mistakes
                    if !combined.userHabits.commonMistakes.isEmpty {
                        Text("Detected Issues")
                            .font(.headline)
                        
                        ForEach(combined.userHabits.commonMistakes, id: \.self) { mistake in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                
                                Text(mistake)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func analyzeRecordings() {
        if let recording = recording {
            insights = RecordingAnalytics.analyzeRecording(recording)
        } else if !recordings.isEmpty {
            combinedInsights = RecordingAnalytics.analyzeMultipleRecordings(recordings)
        }
    }
    
    private func exportToMarkdown() {
        guard let insights = insights, let recording = recording else { return }
        
        let markdown = RecordingAnalytics.exportToMarkdown(insights, recordingName: recording.name)
        
        // Save to file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(recording.name)_analytics.md"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    try markdown.write(to: url, atomically: true, encoding: .utf8)
                    showExportSuccess()
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
    
    private func exportToJSON() {
        guard let insights = insights, let recording = recording else { return }
        
        guard let json = RecordingAnalytics.exportToJSON(insights, recordingName: recording.name) else { return }
        
        // Save to file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "\(recording.name)_analytics.json"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    try json.write(to: url, atomically: true, encoding: .utf8)
                    showExportSuccess()
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
    
    private func copyToClipboard() {
        var markdown = ""
        
        if let insights = insights, let recording = recording {
            // Single recording analytics
            markdown = RecordingAnalytics.exportToMarkdown(insights, recordingName: recording.name)
        } else if let combined = combinedInsights {
            // Multiple recordings analytics
            markdown = generateCombinedMarkdown(combined)
        } else {
            print("No analytics data to copy")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
        
        showExportSuccess()
    }
    
    private func generateCombinedMarkdown(_ combined: RecordingAnalytics.CombinedInsights) -> String {
        var markdown = "# Combined Recordings Analytics Report\n\n"
        markdown += "**Total Recordings:** \(combined.totalRecordings)\n"
        markdown += "**Total Actions:** \(combined.totalActions)\n"
        markdown += "**Average Duration:** \(formatDuration(combined.averageDuration))\n\n"
        
        // INDIVIDUAL RECORDING DETAILS
        markdown += "## Individual Recording Analysis\n\n"
        for recording in recordings {
            let insights = RecordingAnalytics.analyzeRecording(recording)
            
            markdown += "### Recording: '\(recording.name)'\n"
            markdown += "- **Actions:** \(recording.actions.count)\n"
            markdown += "- **Duration:** \(formatDuration(insights.duration))\n"
            markdown += "- **Wait Time:** \(Int(insights.waitTimeAnalysis.waitTimePercentage))%\n"
            markdown += "- **Toolbar Clicks:** \(insights.toolbarUsage.toolbarClicks)\n"
            markdown += "- **Home Button Clicks:** \(insights.toolbarUsage.homeButtonClicks)\n"
            
            // Show ALL actions for this recording
            markdown += "\n**Full Action Sequence:**\n"
            for (index, action) in recording.actions.enumerated() {
                let actionDesc = action.description
                markdown += "\(index + 1). \(actionDesc)\n"
            }
            
            // Show click positions for this recording
            markdown += "\n**Click Positions Summary:**\n"
            for hotspot in insights.hotspots {
                let x = Int(hotspot.relativePosition.x * 100)
                let y = Int(hotspot.relativePosition.y * 100)
                markdown += "  - (\(x)%, \(y)%): \(hotspot.frequency) clicks\n"
            }
            markdown += "\n"
        }
        
        markdown += "## Aggregated Click Positions\n\n"
        markdown += "| Position (%) | Total Clicks | From Recordings |\n"
        markdown += "|-------------|--------------|----------------|\n"
        
        // Track which recordings contributed to each position
        var positionSources: [String: [String]] = [:]
        for recording in recordings {
            let insights = RecordingAnalytics.analyzeRecording(recording)
            for hotspot in insights.hotspots {
                let key = "(\(Int(hotspot.relativePosition.x * 100))%, \(Int(hotspot.relativePosition.y * 100))%)"
                if positionSources[key] == nil {
                    positionSources[key] = []
                }
                positionSources[key]?.append(recording.name)
            }
        }
        
        for area in combined.userHabits.preferredClickAreas {
            let x = Int(area.relativePosition.x * 100)
            let y = Int(area.relativePosition.y * 100)
            let posKey = "(\(x)%, \(y)%)"
            let sources = positionSources[posKey]?.joined(separator: ", ") ?? "Multiple"
            markdown += "| \(posKey) | \(area.frequency) | \(sources) |\n"
        }
        markdown += "\n"
        
        markdown += "## Common Patterns\n\n"
        for pattern in combined.commonPatterns {
            markdown += "- **\(pattern.name)**: \(pattern.frequency)x\n"
            markdown += "  - Sequence: `\(pattern.sequence.joined(separator: " → "))`\n"
            markdown += "  - Avg Duration: \(formatDuration(pattern.averageDuration))\n\n"
        }
        
        markdown += "## Optimization Opportunities\n\n"
        for suggestion in combined.optimizationOpportunities {
            markdown += "- **\(suggestion.type)**: \(suggestion.description)\n"
            if suggestion.potentialTimeSaving > 0 {
                markdown += "  - Potential time saving: \(formatDuration(suggestion.potentialTimeSaving))\n"
            }
            markdown += "\n"
        }
        
        markdown += "## Summary\n\n"
        markdown += "- **Average Actions per Recording:** \(String(format: "%.1f", combined.userHabits.averageActionsPerRecording))\n"
        markdown += "- **All Click Areas:**\n"
        for area in combined.userHabits.preferredClickAreas {
            let x = Int(area.relativePosition.x * 100)
            let y = Int(area.relativePosition.y * 100)
            markdown += "  - Position (\(x)%, \(y)%): \(area.frequency) clicks\n"
        }
        
        if !combined.userHabits.commonMistakes.isEmpty {
            markdown += "\n**Common Issues:**\n"
            for mistake in combined.userHabits.commonMistakes {
                markdown += "- \(mistake)\n"
            }
        }
        
        return markdown
    }
    
    private func showExportSuccess() {
        withAnimation {
            showingExportSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingExportSuccess = false
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.1fms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
    
    private func waitTimeColor(_ percentage: Double) -> Color {
        if percentage < 20 { return .green }
        if percentage < 40 { return .yellow }
        return .orange
    }
    
    private func heatmapColor(for frequency: Int) -> Color {
        if frequency >= 10 { return .red }
        if frequency >= 5 { return .orange }
        if frequency >= 2 { return .yellow }
        return .blue
    }
    
    private func iconForActionType(_ type: String) -> String {
        switch type {
        case "mouseClick": return "cursorarrow.click"
        case "mouseDrag": return "arrow.up.and.down.and.arrow.left.and.right"
        case "mouseMove": return "cursorarrow"
        case "wait": return "clock"
        case "keyPress": return "keyboard"
        default: return "circle"
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ToolbarStatView: View {
    let icon: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text("\(count)")
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct OptimizationCard: View {
    let suggestion: RecordingAnalytics.OptimizationSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text(suggestion.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if suggestion.potentialTimeSaving > 0 {
                    Text("Save ~\(formatTime(suggestion.potentialTimeSaving))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !suggestion.affectedRecordings.isEmpty {
                Text("Affects: \(suggestion.affectedRecordings.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time < 1 {
            return String(format: "%.0fms", time * 1000)
        } else {
            return String(format: "%.1fs", time)
        }
    }
}

struct HeatmapGrid: View {
    let hotspots: [RecordingAnalytics.HeatmapPoint]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                ForEach(0..<10) { i in
                    Path { path in
                        let x = geometry.size.width * CGFloat(i) / 10
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    
                    Path { path in
                        let y = geometry.size.height * CGFloat(i) / 10
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                }
                
                // Hotspot circles
                ForEach(Array(hotspots.enumerated()), id: \.offset) { _, hotspot in
                    Circle()
                        .fill(heatmapColorForFrequency(hotspot.frequency))
                        .frame(width: min(CGFloat(hotspot.frequency) * 5 + 10, 40),
                               height: min(CGFloat(hotspot.frequency) * 5 + 10, 40))
                        .position(
                            x: geometry.size.width * hotspot.relativePosition.x,
                            y: geometry.size.height * hotspot.relativePosition.y
                        )
                        .opacity(0.7)
                }
            }
        }
    }
    
    private func heatmapColorForFrequency(_ frequency: Int) -> Color {
        if frequency >= 10 { return .red }
        if frequency >= 5 { return .orange }
        if frequency >= 2 { return .yellow }
        return .blue
    }
}