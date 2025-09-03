//
//  RecordingAnalytics.swift
//  iosAppTester
//
//  Analytics and pattern extraction from recorded actions
//

import Foundation
import CoreGraphics

class RecordingAnalytics {
    
    // MARK: - Data Structures
    
    struct ActionPattern {
        let type: String
        let frequency: Int
        let averagePosition: CGPoint?
        let commonSequences: [String]
    }
    
    struct RecordingInsights {
        let totalActions: Int
        let duration: TimeInterval
        let actionsPerSecond: Double
        let mostFrequentActions: [ActionPattern]
        let hotspots: [HeatmapPoint]
        let commonWorkflows: [WorkflowPattern]
        let waitTimeAnalysis: WaitTimeStats
        let toolbarUsage: ToolbarStats
    }
    
    struct HeatmapPoint {
        let position: CGPoint
        let relativePosition: CGPoint
        let frequency: Int
        let actionType: String
    }
    
    struct WorkflowPattern {
        let sequence: [String]
        let frequency: Int
        let averageDuration: TimeInterval
        let name: String
    }
    
    struct WaitTimeStats {
        let totalWaitTime: TimeInterval
        let averageWaitBetweenActions: TimeInterval
        let longestWait: TimeInterval
        let waitTimePercentage: Double
    }
    
    struct ToolbarStats {
        let toolbarClicks: Int
        let homeButtonClicks: Int
        let appSwitcherClicks: Int
        let toolbarHovers: Int
        let toolbarClickPercentage: Double
    }
    
    struct CombinedInsights {
        let totalRecordings: Int
        let totalActions: Int
        let averageDuration: TimeInterval
        let commonPatterns: [WorkflowPattern]
        let optimizationOpportunities: [OptimizationSuggestion]
        let userHabits: UserHabits
    }
    
    struct OptimizationSuggestion {
        let type: String
        let description: String
        let potentialTimeSaving: TimeInterval
        let affectedRecordings: [String]
    }
    
    struct UserHabits {
        let preferredClickAreas: [HeatmapPoint]
        let averageActionsPerRecording: Double
        let mostProductiveTimeOfDay: String?
        let commonMistakes: [String]
    }
    
    // MARK: - Export Methods
    
    static func exportToMarkdown(_ insights: RecordingInsights, recordingName: String) -> String {
        var markdown = "# Recording Analytics Report\n\n"
        markdown += "**Recording:** \(recordingName)\n"
        markdown += "**Generated:** \(Date().formatted())\n\n"
        
        markdown += "## Overview\n\n"
        markdown += "- **Total Actions:** \(insights.totalActions)\n"
        markdown += "- **Duration:** \(formatDuration(insights.duration))\n"
        markdown += "- **Actions per Second:** \(String(format: "%.2f", insights.actionsPerSecond))\n\n"
        
        markdown += "## Toolbar Usage\n\n"
        markdown += "The recording shows the following toolbar interactions:\n\n"
        markdown += "- **Home Button Clicks:** \(insights.toolbarUsage.homeButtonClicks)\n"
        markdown += "- **App Switcher Clicks:** \(insights.toolbarUsage.appSwitcherClicks)\n"
        markdown += "- **Total Toolbar Clicks:** \(insights.toolbarUsage.toolbarClicks)\n"
        markdown += "- **Toolbar Hovers:** \(insights.toolbarUsage.toolbarHovers)\n"
        markdown += "- **Toolbar Click Percentage:** \(String(format: "%.1f%%", insights.toolbarUsage.toolbarClickPercentage))\n\n"
        
        // DETAILED CLICK POSITIONS - THIS IS CRITICAL
        markdown += "## ALL Click Positions (DETAILED)\n\n"
        markdown += "| Click # | Absolute Position | Relative Position (%) | Type | Description |\n"
        markdown += "|---------|------------------|----------------------|------|-------------|\n"
        
        var clickCount = 0
        for action in insights.mostFrequentActions {
            if action.type == "mouseClick", let pos = action.averagePosition {
                clickCount += 1
                // Find the relative positions from hotspots
                if let hotspot = insights.hotspots.first(where: { 
                    abs($0.position.x - pos.x) < 50 && abs($0.position.y - pos.y) < 50 
                }) {
                    let relX = Int(hotspot.relativePosition.x * 100)
                    let relY = Int(hotspot.relativePosition.y * 100)
                    
                    var desc = ""
                    if relY < 10 {
                        if relX > 80 && relX < 90 {
                            desc = "**HOME BUTTON POSITION**"
                        } else if relX > 37 && relX < 47 {
                            desc = "Old Home position (doesn't work)"
                        } else if relX > 47 && relX < 57 {
                            desc = "App Switcher"
                        } else {
                            desc = "Toolbar area"
                        }
                    } else {
                        desc = "Main content"
                    }
                    
                    markdown += "| \(clickCount) | (\(Int(pos.x)), \(Int(pos.y))) | **(\(relX)%, \(relY)%)** | \(action.type) | \(desc) |\n"
                }
            }
        }
        markdown += "\n"
        
        // ACTUAL HOME BUTTON INFORMATION
        if insights.toolbarUsage.homeButtonClicks > 0 {
            markdown += "### 🎯 ACTUAL Home Button Usage Pattern\n\n"
            markdown += "Based on this recording, the Home button is successfully triggered at:\n\n"
            
            // Find toolbar clicks and their exact positions
            for hotspot in insights.hotspots {
                let x = Int(hotspot.relativePosition.x * 100)
                let y = Int(hotspot.relativePosition.y * 100)
                
                if y < 10 && x > 80 && x < 90 {
                    markdown += "- **Position:** \(x)% from left, \(y)% from top\n"
                    markdown += "- **Frequency:** \(hotspot.frequency) successful clicks\n"
                    markdown += "- **Absolute:** (\(Int(hotspot.position.x)), \(Int(hotspot.position.y)))\n\n"
                }
            }
            
            markdown += "**Working Sequence:**\n"
            markdown += "1. Hover over top area to reveal toolbar\n"
            markdown += "2. Wait 500ms for toolbar to appear\n"
            markdown += "3. Click at **85-86% width** (NOT 42%!)\n\n"
        }
        
        markdown += "## Most Frequent Actions (FULL LIST)\n\n"
        markdown += "| Action Type | Frequency | Average Position | Sequences |\n"
        markdown += "|------------|-----------|------------------|----------|\n"
        for pattern in insights.mostFrequentActions {
            let posStr = pattern.averagePosition.map { pos in
                "(\(Int(pos.x)), \(Int(pos.y)))"
            } ?? "N/A"
            let seqStr = pattern.commonSequences.prefix(2).joined(separator: " | ")
            markdown += "| \(pattern.type) | \(pattern.frequency)x | \(posStr) | \(seqStr) |\n"
        }
        markdown += "\n"
        
        markdown += "## Common Workflows\n\n"
        for (index, workflow) in insights.commonWorkflows.enumerated() {
            markdown += "### Workflow \(index + 1): \(workflow.name)\n"
            markdown += "- **Frequency:** \(workflow.frequency) times\n"
            markdown += "- **Average Duration:** \(formatDuration(workflow.averageDuration))\n"
            markdown += "- **Full Sequence:** `\(workflow.sequence.joined(separator: " → "))`\n\n"
        }
        
        markdown += "## Complete Click Heatmap (ALL LOCATIONS)\n\n"
        markdown += "| Position (%) | Absolute | Clicks | Description |\n"
        markdown += "|-------------|----------|--------|-------------|\n"
        for hotspot in insights.hotspots {
            let x = Int(hotspot.relativePosition.x * 100)
            let y = Int(hotspot.relativePosition.y * 100)
            let absX = Int(hotspot.position.x)
            let absY = Int(hotspot.position.y)
            var description = ""
            
            // Add context based on position
            if y < 10 {
                if x > 80 && x < 90 {
                    description = "**HOME BUTTON (WORKING)**"
                } else if x > 37 && x < 47 {
                    description = "Old Home (broken)"
                } else if x > 47 && x < 57 {
                    description = "App Switcher"
                } else {
                    description = "Toolbar"
                }
            } else if y > 90 {
                description = "Bottom (tab bar)"
            } else {
                description = "Main content"
            }
            
            markdown += "| **(\(x)%, \(y)%)** | (\(absX), \(absY)) | \(hotspot.frequency) | \(description) |\n"
        }
        markdown += "\n"
        
        markdown += "## Wait Time Analysis\n\n"
        markdown += "- **Total Wait Time:** \(formatDuration(insights.waitTimeAnalysis.totalWaitTime))\n"
        markdown += "- **Average Wait Between Actions:** \(formatDuration(insights.waitTimeAnalysis.averageWaitBetweenActions))\n"
        markdown += "- **Longest Wait:** \(formatDuration(insights.waitTimeAnalysis.longestWait))\n"
        markdown += "- **Wait Time Percentage:** \(String(format: "%.1f%%", insights.waitTimeAnalysis.waitTimePercentage))\n\n"
        
        if insights.waitTimeAnalysis.waitTimePercentage > 30 {
            markdown += "⚠️ **High wait time detected** - \(Int(insights.waitTimeAnalysis.waitTimePercentage))% of time is waiting\n\n"
        }
        
        markdown += "## Key Findings\n\n"
        markdown += "- Home button works at **85-86% width**, NOT 42%\n"
        markdown += "- Toolbar requires hover + 500ms wait to appear\n"
        markdown += "- Total toolbar interactions: \(insights.toolbarUsage.toolbarClicks)\n\n"
        
        return markdown
    }
    
    static func exportToJSON(_ insights: RecordingInsights, recordingName: String) -> String? {
        let exportData = [
            "recordingName": recordingName,
            "generatedAt": Date().formatted(),
            "overview": [
                "totalActions": insights.totalActions,
                "duration": insights.duration,
                "actionsPerSecond": insights.actionsPerSecond
            ],
            "toolbarUsage": [
                "homeButtonClicks": insights.toolbarUsage.homeButtonClicks,
                "appSwitcherClicks": insights.toolbarUsage.appSwitcherClicks,
                "toolbarClicks": insights.toolbarUsage.toolbarClicks,
                "toolbarClickPercentage": insights.toolbarUsage.toolbarClickPercentage
            ],
            "homeButtonTechnique": [
                "hoverPosition": "50% width, top of window",
                "waitTime": "500ms for toolbar to appear",
                "clickPosition": "42% width from left edge",
                "relativeY": "< 10% from top"
            ],
            "mostFrequentActions": insights.mostFrequentActions.prefix(10).map { pattern in
                [
                    "type": pattern.type,
                    "frequency": pattern.frequency,
                    "averagePosition": pattern.averagePosition.map { ["x": $0.x, "y": $0.y] }
                ]
            },
            "commonWorkflows": insights.commonWorkflows.prefix(5).map { workflow in
                [
                    "name": workflow.name,
                    "sequence": workflow.sequence,
                    "frequency": workflow.frequency,
                    "averageDuration": workflow.averageDuration
                ]
            },
            "clickHeatmap": insights.hotspots.prefix(10).map { hotspot in
                [
                    "relativeX": hotspot.relativePosition.x,
                    "relativeY": hotspot.relativePosition.y,
                    "frequency": hotspot.frequency
                ]
            },
            "waitTimeAnalysis": [
                "totalWaitTime": insights.waitTimeAnalysis.totalWaitTime,
                "averageWait": insights.waitTimeAnalysis.averageWaitBetweenActions,
                "longestWait": insights.waitTimeAnalysis.longestWait,
                "waitPercentage": insights.waitTimeAnalysis.waitTimePercentage
            ]
        ] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting to JSON: \(error)")
            return nil
        }
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
    
    // MARK: - Analysis Methods
    
    static func analyzeRecording(_ recording: ActionRecorder.Recording) -> RecordingInsights {
        let totalActions = recording.actions.count
        let duration = calculateDuration(from: recording.actions)
        let actionsPerSecond = totalActions > 0 ? Double(totalActions) / duration : 0
        
        let mostFrequent = analyzeMostFrequentActions(recording.actions)
        let hotspots = generateHeatmap(from: recording.actions)
        let workflows = detectCommonWorkflows(from: recording.actions)
        let waitStats = analyzeWaitTimes(recording.actions)
        let toolbarStats = analyzeToolbarUsage(recording.actions)
        
        return RecordingInsights(
            totalActions: totalActions,
            duration: duration,
            actionsPerSecond: actionsPerSecond,
            mostFrequentActions: mostFrequent,
            hotspots: hotspots,
            commonWorkflows: workflows,
            waitTimeAnalysis: waitStats,
            toolbarUsage: toolbarStats
        )
    }
    
    static func analyzeMultipleRecordings(_ recordings: [ActionRecorder.Recording]) -> CombinedInsights {
        var allActions: [ActionRecorder.RecordedAction] = []
        var allDurations: [TimeInterval] = []
        
        for recording in recordings {
            allActions.append(contentsOf: recording.actions)
            allDurations.append(calculateDuration(from: recording.actions))
        }
        
        let commonPatterns = findCrossRecordingPatterns(recordings)
        let optimizationOpportunities = findOptimizationOpportunities(recordings)
        let userHabits = analyzeUserHabits(recordings)
        
        return CombinedInsights(
            totalRecordings: recordings.count,
            totalActions: allActions.count,
            averageDuration: allDurations.reduce(0, +) / Double(allDurations.count),
            commonPatterns: commonPatterns,
            optimizationOpportunities: optimizationOpportunities,
            userHabits: userHabits
        )
    }
    
    // MARK: - Pattern Detection
    
    private static func analyzeMostFrequentActions(_ actions: [ActionRecorder.RecordedAction]) -> [ActionPattern] {
        var actionCounts: [String: Int] = [:]
        var actionPositions: [String: [CGPoint]] = [:]
        
        for action in actions {
            let type = action.actionType
            actionCounts[type, default: 0] += 1
            
            if let position = action.position {
                actionPositions[type, default: []].append(position)
            }
        }
        
        return actionCounts.map { type, count in
            let positions = actionPositions[type] ?? []
            let avgPosition = positions.isEmpty ? nil : CGPoint(
                x: positions.map { $0.x }.reduce(0, +) / CGFloat(positions.count),
                y: positions.map { $0.y }.reduce(0, +) / CGFloat(positions.count)
            )
            
            return ActionPattern(
                type: type,
                frequency: count,
                averagePosition: avgPosition,
                commonSequences: findSequencesContaining(type, in: actions)
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    private static func generateHeatmap(from actions: [ActionRecorder.RecordedAction]) -> [HeatmapPoint] {
        var heatmap: [String: (count: Int, positions: [CGPoint], relativePositions: [CGPoint])] = [:]
        
        for action in actions {
            guard let position = action.position,
                  let relativePos = action.relativePosition else { continue }
            
            let key = "\(Int(relativePos.x * 10))-\(Int(relativePos.y * 10))" // Grid of 10x10
            
            if heatmap[key] == nil {
                heatmap[key] = (0, [], [])
            }
            
            heatmap[key]?.count += 1
            heatmap[key]?.positions.append(position)
            heatmap[key]?.relativePositions.append(relativePos)
        }
        
        return heatmap.compactMap { key, data in
            guard !data.positions.isEmpty else { return nil }
            
            let avgPosition = CGPoint(
                x: data.positions.map { $0.x }.reduce(0, +) / CGFloat(data.positions.count),
                y: data.positions.map { $0.y }.reduce(0, +) / CGFloat(data.positions.count)
            )
            
            let avgRelativePosition = CGPoint(
                x: data.relativePositions.map { $0.x }.reduce(0, +) / CGFloat(data.relativePositions.count),
                y: data.relativePositions.map { $0.y }.reduce(0, +) / CGFloat(data.relativePositions.count)
            )
            
            return HeatmapPoint(
                position: avgPosition,
                relativePosition: avgRelativePosition,
                frequency: data.count,
                actionType: "click" // Could be enhanced to track specific types
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    private static func detectCommonWorkflows(from actions: [ActionRecorder.RecordedAction]) -> [WorkflowPattern] {
        var patterns: [String: (count: Int, durations: [TimeInterval])] = [:]
        
        // Look for sequences of 3-5 actions
        for windowSize in 3...5 {
            for i in 0...(actions.count - windowSize) {
                let sequence = actions[i..<(i + windowSize)]
                let sequenceKey = sequence.map { $0.actionType }.joined(separator: "->")
                
                let duration = calculateDuration(from: Array(sequence))
                
                if patterns[sequenceKey] == nil {
                    patterns[sequenceKey] = (0, [])
                }
                
                patterns[sequenceKey]?.count += 1
                patterns[sequenceKey]?.durations.append(duration)
            }
        }
        
        // Filter for patterns that occur at least twice
        return patterns.compactMap { key, data in
            guard data.count >= 2 else { return nil }
            
            let avgDuration = data.durations.reduce(0, +) / Double(data.durations.count)
            let name = nameWorkflow(from: key)
            
            return WorkflowPattern(
                sequence: key.components(separatedBy: "->"),
                frequency: data.count,
                averageDuration: avgDuration,
                name: name
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    // MARK: - Insights Generation
    
    private static func analyzeWaitTimes(_ actions: [ActionRecorder.RecordedAction]) -> WaitTimeStats {
        var totalWait: TimeInterval = 0
        var waitTimes: [TimeInterval] = []
        
        for action in actions {
            if case .wait(let seconds) = action {
                totalWait += seconds
                waitTimes.append(seconds)
            }
        }
        
        let totalDuration = calculateDuration(from: actions)
        let avgWait = waitTimes.isEmpty ? 0 : waitTimes.reduce(0, +) / Double(waitTimes.count)
        let longestWait = waitTimes.max() ?? 0
        let waitPercentage = totalDuration > 0 ? (totalWait / totalDuration) * 100 : 0
        
        return WaitTimeStats(
            totalWaitTime: totalWait,
            averageWaitBetweenActions: avgWait,
            longestWait: longestWait,
            waitTimePercentage: waitPercentage
        )
    }
    
    private static func analyzeToolbarUsage(_ actions: [ActionRecorder.RecordedAction]) -> ToolbarStats {
        var toolbarClicks = 0
        var homeClicks = 0
        var appSwitcherClicks = 0
        var toolbarHovers = 0
        
        for action in actions {
            if let relPos = action.relativePosition {
                // Toolbar is in top 10% of window
                if relPos.y < 0.1 {
                    if case .mouseClick = action {
                        toolbarClicks += 1
                        
                        // Home button at 85% width (based on actual recordings)
                        if relPos.x > 0.80 && relPos.x < 0.90 {
                            homeClicks += 1
                        }
                        // App switcher around 52% width
                        else if relPos.x > 0.47 && relPos.x < 0.57 {
                            appSwitcherClicks += 1
                        }
                    } else if case .mouseMove = action {
                        toolbarHovers += 1
                    }
                }
            }
        }
        
        let totalClicks = actions.filter { 
            if case .mouseClick = $0 { return true }
            return false
        }.count
        
        let toolbarPercentage = totalClicks > 0 ? (Double(toolbarClicks) / Double(totalClicks)) * 100 : 0
        
        return ToolbarStats(
            toolbarClicks: toolbarClicks,
            homeButtonClicks: homeClicks,
            appSwitcherClicks: appSwitcherClicks,
            toolbarHovers: toolbarHovers,
            toolbarClickPercentage: toolbarPercentage
        )
    }
    
    // MARK: - Cross-Recording Analysis
    
    private static func findCrossRecordingPatterns(_ recordings: [ActionRecorder.Recording]) -> [WorkflowPattern] {
        var allPatterns: [String: (count: Int, durations: [TimeInterval], recordings: Set<String>)] = [:]
        
        for recording in recordings {
            let patterns = detectCommonWorkflows(from: recording.actions)
            for pattern in patterns {
                let key = pattern.sequence.joined(separator: "->")
                
                if allPatterns[key] == nil {
                    allPatterns[key] = (0, [], Set())
                }
                
                allPatterns[key]?.count += pattern.frequency
                allPatterns[key]?.durations.append(pattern.averageDuration)
                allPatterns[key]?.recordings.insert(recording.name)
            }
        }
        
        // Return patterns that appear in multiple recordings
        return allPatterns.compactMap { key, data in
            guard data.recordings.count >= 2 else { return nil }
            
            let avgDuration = data.durations.reduce(0, +) / Double(data.durations.count)
            
            return WorkflowPattern(
                sequence: key.components(separatedBy: "->"),
                frequency: data.count,
                averageDuration: avgDuration,
                name: "Cross-recording: \(nameWorkflow(from: key))"
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    private static func findOptimizationOpportunities(_ recordings: [ActionRecorder.Recording]) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        for recording in recordings {
            // Check for excessive waits
            let waitStats = analyzeWaitTimes(recording.actions)
            if waitStats.waitTimePercentage > 30 {
                suggestions.append(OptimizationSuggestion(
                    type: "Excessive Wait Time",
                    description: "Recording '\(recording.name)' has \(Int(waitStats.waitTimePercentage))% wait time. Consider reducing delays.",
                    potentialTimeSaving: waitStats.totalWaitTime * 0.5,
                    affectedRecordings: [recording.name]
                ))
            }
            
            // Check for repeated clicks in same location
            var lastClick: (CGPoint, Date)? = nil
            for (index, action) in recording.actions.enumerated() {
                if case .mouseClick(_, _, let relX, let relY, _) = action {
                    let currentPos = CGPoint(x: relX, y: relY)
                    
                    if let (lastPos, _) = lastClick {
                        let distance = hypot(currentPos.x - lastPos.x, currentPos.y - lastPos.y)
                        if distance < 0.05 { // Within 5% of window size
                            suggestions.append(OptimizationSuggestion(
                                type: "Duplicate Clicks",
                                description: "Multiple clicks at same location in '\(recording.name)' at action #\(index)",
                                potentialTimeSaving: 0.5,
                                affectedRecordings: [recording.name]
                            ))
                        }
                    }
                    
                    lastClick = (currentPos, Date())
                }
            }
        }
        
        return suggestions
    }
    
    private static func analyzeUserHabits(_ recordings: [ActionRecorder.Recording]) -> UserHabits {
        var allHeatmapPoints: [HeatmapPoint] = []
        var totalActions = 0
        var mistakes: [String] = []
        
        for recording in recordings {
            let heatmap = generateHeatmap(from: recording.actions)
            allHeatmapPoints.append(contentsOf: heatmap)
            totalActions += recording.actions.count
            
            // Detect potential mistakes (quick succession of different actions)
            for i in 0..<(recording.actions.count - 2) {
                if case .mouseClick = recording.actions[i],
                   case .mouseClick = recording.actions[i + 1],
                   case .wait(let seconds) = recording.actions[i + 2],
                   seconds < 0.5 {
                    mistakes.append("Quick correction detected in '\(recording.name)'")
                }
            }
        }
        
        // Aggregate heatmap data
        let preferredAreas = Dictionary(grouping: allHeatmapPoints) { point in
            "\(Int(point.relativePosition.x * 10))-\(Int(point.relativePosition.y * 10))"
        }.map { _, points in
            HeatmapPoint(
                position: points[0].position,
                relativePosition: points[0].relativePosition,
                frequency: points.reduce(0) { $0 + $1.frequency },
                actionType: "aggregate"
            )
        }.sorted { $0.frequency > $1.frequency }.prefix(5).map { $0 }
        
        let avgActions = Double(totalActions) / Double(max(recordings.count, 1))
        
        return UserHabits(
            preferredClickAreas: Array(preferredAreas),
            averageActionsPerRecording: avgActions,
            mostProductiveTimeOfDay: nil, // Could analyze recording timestamps
            commonMistakes: mistakes
        )
    }
    
    // MARK: - Helper Methods
    
    private static func calculateDuration(from actions: [ActionRecorder.RecordedAction]) -> TimeInterval {
        var duration: TimeInterval = 0
        
        for action in actions {
            if case .wait(let seconds) = action {
                duration += seconds
            } else {
                duration += 0.1 // Assume 100ms for each action
            }
        }
        
        return duration
    }
    
    private static func findSequencesContaining(_ actionType: String, in actions: [ActionRecorder.RecordedAction]) -> [String] {
        var sequences: [String] = []
        
        for (index, action) in actions.enumerated() {
            if action.actionType == actionType {
                // Get surrounding context (2 actions before and after)
                let start = max(0, index - 2)
                let end = min(actions.count, index + 3)
                
                let sequence = actions[start..<end].map { $0.actionType }.joined(separator: "->")
                if !sequences.contains(sequence) {
                    sequences.append(sequence)
                }
                
                if sequences.count >= 3 { break } // Limit to 3 examples
            }
        }
        
        return sequences
    }
    
    private static func nameWorkflow(from sequence: String) -> String {
        let actions = sequence.components(separatedBy: "->")
        
        // Common patterns
        if actions.contains("mouseMove") && actions.contains("mouseClick") && actions.filter({ $0 == "mouseClick" }).count == 1 {
            if sequence.contains("wait") {
                return "Hover and Click"
            }
            return "Quick Click"
        }
        
        if actions.filter({ $0 == "mouseClick" }).count >= 2 {
            return "Multiple Clicks"
        }
        
        if actions.contains("mouseDrag") {
            return "Drag Gesture"
        }
        
        if actions.filter({ $0 == "wait" }).count >= 2 {
            return "Slow Interaction"
        }
        
        return "Custom Workflow"
    }
}

// MARK: - Extensions for ActionRecorder.RecordedAction

extension ActionRecorder.RecordedAction {
    var actionType: String {
        switch self {
        case .mouseClick: return "mouseClick"
        case .mouseDown: return "mouseDown"
        case .mouseUp: return "mouseUp"
        case .mouseDrag: return "mouseDrag"
        case .mouseMove: return "mouseMove"
        case .keyPress: return "keyPress"
        case .wait: return "wait"
        case .windowMoved: return "windowMoved"
        }
    }
    
    var position: CGPoint? {
        switch self {
        case .mouseClick(let x, let y, _, _, _):
            return CGPoint(x: x, y: y)
        case .mouseDown(let x, let y, _, _):
            return CGPoint(x: x, y: y)
        case .mouseUp(let x, let y, _, _):
            return CGPoint(x: x, y: y)
        case .mouseDrag(let fromX, let fromY, _, _, _, _, _, _):
            return CGPoint(x: fromX, y: fromY)
        case .mouseMove(let x, let y, _, _):
            return CGPoint(x: x, y: y)
        default:
            return nil
        }
    }
    
    var relativePosition: CGPoint? {
        switch self {
        case .mouseClick(_, _, let relX, let relY, _):
            return CGPoint(x: relX, y: relY)
        case .mouseDown(_, _, let relX, let relY):
            return CGPoint(x: relX, y: relY)
        case .mouseUp(_, _, let relX, let relY):
            return CGPoint(x: relX, y: relY)
        case .mouseDrag(_, _, _, _, let fromRelX, let fromRelY, _, _):
            return CGPoint(x: fromRelX, y: fromRelY)
        case .mouseMove(_, _, let relX, let relY):
            return CGPoint(x: relX, y: relY)
        default:
            return nil
        }
    }
}