//
//  TaskArcGeometry.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Foundation
import CoreGraphics


struct TaskArcGeometry {
    let center: CGPoint
    let radius: CGFloat
    let configuration: TaskArcConfiguration
    let task: TaskOnRing
    
    // MARK: - Computed Properties
    var taskDurationMinutes: Double {
        task.duration / 60
    }
    
    var shortTaskScale: CGFloat {
        let isShortTask = taskDurationMinutes < 60
        return isShortTask ? max(0.6, taskDurationMinutes / 60) : 1.0
    }
    
    var analogOffset: CGFloat {
        let tOffset = configuration.interpolationFactor
        return TaskArcConstants.minOffset + 
               (TaskArcConstants.maxOffset - TaskArcConstants.minOffset) * tOffset
    }
    
    var arcRadius: CGFloat {
        if configuration.isAnalog {
            return radius + (configuration.outerRingLineWidth / 2) + analogOffset
        } else {
            return radius + configuration.arcLineWidth / 2
        }
    }
    
    var iconRadius: CGFloat {
        let editingOffset: CGFloat = configuration.isEditingMode ? 25 : 0
        let baseRadius: CGFloat = configuration.isAnalog ? 
            arcRadius : 
            arcRadius - TaskArcConstants.iconSpacingFromArc
        
        return baseRadius + editingOffset
    }
    
    var iconSize: CGFloat {
        TaskArcConstants.baseIconSize
    }
    
    var iconFontSize: CGFloat {
        if configuration.isAnalog {
            let tRing = configuration.interpolationFactor
            return TaskArcConstants.minIconFontSize + 
                   (TaskArcConstants.maxIconFontSize - TaskArcConstants.minIconFontSize) * tRing
        } else {
            return TaskArcConstants.minIconFontSize
        }
    }
    
    var handleSize: (width: CGFloat, height: CGFloat) {
        let t = configuration.interpolationFactor
        let baseHandleSize: CGFloat = configuration.isAnalog ?
            20 + (30 - 20) * t : 20
        let baseHandleWidth: CGFloat = baseHandleSize
        let handleHeight: CGFloat = baseHandleSize * pow(shortTaskScale, 2)
        
        return (width: baseHandleWidth, height: handleHeight)
    }
    
    // MARK: - Angle Calculations
    var angles: (start: Angle, end: Angle) {
        RingTimeCalculator.calculateAngles(for: task)
    }
    
    var midAngle: Angle {
        let (startAngle, endAngle) = angles
        return RingTimeCalculator.calculateMidAngle(start: startAngle, end: endAngle)
    }
    
    // MARK: - Position Calculations
    func iconPosition() -> CGPoint {
        let midAngleRadians = midAngle.radians
        return CGPoint(
            x: center.x + iconRadius * cos(midAngleRadians),
            y: center.y + iconRadius * sin(midAngleRadians)
        )
    }
    
    func handlePosition(for angle: Angle) -> CGPoint {
        return CGPoint(
            x: center.x + arcRadius * cos(angle.radians),
            y: center.y + arcRadius * sin(angle.radians)
        )
    }
    
    // MARK: - Path Generation
    func createArcPath() -> Path {
        let (startAngle, endAngle) = angles
        return Path { path in
            path.addArc(
                center: center,
                radius: arcRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }
    
    func createGestureArea() -> Path {
        let (startAngle, endAngle) = angles
        return Path { path in
            path.addArc(
                center: center,
                radius: radius + 70,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: radius - 10,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        }
    }
} 
