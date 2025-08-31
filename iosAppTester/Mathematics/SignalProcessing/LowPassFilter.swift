//
//  LowPassFilter.swift
//  Signal Processing - Low Pass Filtering
//
//  Single Responsibility: Smooth noisy input signals
//

import Foundation

class LowPassFilter {
    private let alpha: Double // Smoothing factor (0-1)
    private var filteredValue: Double?
    
    init(cutoffFrequency: Double, sampleRate: Double = 60.0) {
        // Calculate alpha from cutoff frequency
        let rc = 1.0 / (2.0 * .pi * cutoffFrequency)
        let dt = 1.0 / sampleRate
        self.alpha = dt / (rc + dt)
    }
    
    init(alpha: Double) {
        self.alpha = min(1.0, max(0.0, alpha))
    }
    
    // Filter a single value
    func filter(_ value: Double) -> Double {
        if let previous = filteredValue {
            filteredValue = alpha * value + (1 - alpha) * previous
        } else {
            filteredValue = value
        }
        return filteredValue!
    }
    
    // Reset the filter
    func reset() {
        filteredValue = nil
    }
}

// 2D Low Pass Filter
class LowPassFilter2D {
    private let xFilter: LowPassFilter
    private let yFilter: LowPassFilter
    
    init(cutoffFrequency: Double, sampleRate: Double = 60.0) {
        xFilter = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
        yFilter = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
    }
    
    init(alpha: Double) {
        xFilter = LowPassFilter(alpha: alpha)
        yFilter = LowPassFilter(alpha: alpha)
    }
    
    // Filter a 2D point
    func filter(_ point: Vector2D) -> Vector2D {
        Vector2D(
            x: xFilter.filter(point.x),
            y: yFilter.filter(point.y)
        )
    }
    
    // Reset filters
    func reset() {
        xFilter.reset()
        yFilter.reset()
    }
}