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
    static let gestureAreaExpansion: CGFloat = 70
    static let gestureAreaInnerReduction: CGFloat = 10
    
    // MARK: - Handle Dimensions
    static let minHandleSize: CGFloat = 20
    static let maxHandleSize: CGFloat = 30
    static let handleStrokeWidth: CGFloat = 2
    
    // MARK: - Animation
    static let appearanceAnimationDuration: Double = 0.3
    static let disappearanceAnimationDuration: Double = 0.3
    static let pressAnimationDuration: Double = 0.1
    static let pressScale: CGFloat = 1.05
    static let iconScaleMultiplier: CGFloat = 1.1
    static let appearanceDelay: Double = 0.1
    static let pressAnimationDelay: Double = 0.2
    
    // MARK: - Haptic Feedback Delays
    static let hapticFeedbackDelay: Double = 0.5
    
    // MARK: - Time Label Dimensions
    static let thinTimeMarkerWidth: CGFloat = 40
    static let thinTimeMarkerHeight: CGFloat = 6
    static let timeMarkerHeight: CGFloat = 16
    static let timeMarkerPadding: CGFloat = 6
    static let timeMarkerCharacterWidth: CGFloat = 6
    
    // MARK: - Drag Preview
    static let dragPreviewOffsetFromArc: CGFloat = 3
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
    
    var editingOffset: CGFloat {
        isEditingMode ? 25 : 0
    }
} 