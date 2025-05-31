//
//  TaskArcConstants.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskArcConstants {
    // MARK: - Ring Dimensions
    static let minOuterRingWidth: CGFloat = 20
    static let maxOuterRingWidth: CGFloat = 38
    static let minArcWidth: CGFloat = 20
    static let maxArcWidth: CGFloat = 32
    
    // MARK: - Offsets
    static let minOffset: CGFloat = 10
    static let maxOffset: CGFloat = 0
    static let minIconOffset: CGFloat = 0
    static let minAnalogIconOffset: CGFloat = -16
    static let maxAnalogIconOffset: CGFloat = -4
    static let iconSpacingFromArc: CGFloat = 4
    
    // MARK: - Icon Sizes
    static let baseIconSize: CGFloat = 18
    static let minIconFontSize: CGFloat = 10
    static let maxIconFontSize: CGFloat = 17
    
    // MARK: - Time Display
    static let timeFontSize: CGFloat = 10
    static let timeTextOffset: CGFloat = -8
    
    // MARK: - Task Constraints
    static let minimumDuration: TimeInterval = 20 * 60 // 20 минут
    static let shortTaskThreshold: TimeInterval = 60 * 60 // 1 час
    
    // MARK: - Touch Areas
    static let minTouchArea: CGFloat = 35
    static let expandedTouchArea: CGFloat = 44
    
    // MARK: - Animation
    static let appearanceAnimationDuration: Double = 0.3
    static let disappearanceAnimationDuration: Double = 0.3
    static let pressAnimationDuration: Double = 0.1
    static let pressScale: CGFloat = 1.05
    
    // MARK: - Haptic Feedback Delays
    static let hapticFeedbackDelay: Double = 0.5
}

struct TaskArcConfiguration {
    let isAnalog: Bool
    let arcLineWidth: CGFloat
    let outerRingLineWidth: CGFloat
    let isEditingMode: Bool
    let showTimeOnlyForActiveTask: Bool
    
    var interpolationFactor: CGFloat {
        (outerRingLineWidth - TaskArcConstants.minOuterRingWidth) / 
        (TaskArcConstants.maxOuterRingWidth - TaskArcConstants.minOuterRingWidth)
    }
} 