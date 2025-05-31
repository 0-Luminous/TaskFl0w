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
        let isShortTask = taskDurationMinutes < TaskArcConstants.shortTaskThreshold / 60
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
        let baseRadius: CGFloat = configuration.isAnalog ? 
            arcRadius : 
            arcRadius - TaskArcConstants.iconSpacingFromArc
        
        return baseRadius + configuration.editingOffset
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
            TaskArcConstants.minHandleSize + (TaskArcConstants.maxHandleSize - TaskArcConstants.minHandleSize) * t : 
            TaskArcConstants.minHandleSize
        let baseHandleWidth: CGFloat = baseHandleSize
        let handleHeight: CGFloat = baseHandleSize * pow(shortTaskScale, 2)
        
        return (width: baseHandleWidth, height: handleHeight)
    }
    
    var touchAreaSize: (width: CGFloat, height: CGFloat) {
        let (handleWidth, handleHeight) = handleSize
        let touchAreaWidth: CGFloat = max(handleWidth, TaskArcConstants.minTouchArea)
        let touchAreaHeight: CGFloat = shortTaskScale > 0.8 ? 
            max(handleHeight, TaskArcConstants.expandedTouchArea) : 
            handleHeight * 1.5
        
        return (width: touchAreaWidth, height: touchAreaHeight)
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
    
    func timeMarkerPosition(for angle: Angle, isThin: Bool = false) -> CGPoint {
        let markerRadius = isThin ? 
            arcRadius - TaskArcConstants.dragPreviewOffsetFromArc : 
            arcRadius + TaskArcConstants.timeTextOffset
        
        return CGPoint(
            x: center.x + markerRadius * cos(angle.radians),
            y: center.y + markerRadius * sin(angle.radians)
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
                radius: radius + TaskArcConstants.gestureAreaExpansion,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: radius - TaskArcConstants.gestureAreaInnerReduction,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        }
    }
    
    func createDragPreviewArea() -> Path {
        let (startAngle, endAngle) = angles
        return Path { path in
            // Основная дуга
            path.addArc(
                center: center,
                radius: arcRadius + configuration.arcLineWidth/2,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: arcRadius - configuration.arcLineWidth/2,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
            
            // Добавляем маркеры времени если нужно
            addTimeMarkersToPath(&path, startAngle: startAngle, endAngle: endAngle)
        }
    }
    
    private func addTimeMarkersToPath(_ path: inout Path, startAngle: Angle, endAngle: Angle) {
        let shouldShowTimeMarkers = !configuration.isAnalog && 
            !configuration.isEditingMode && 
            (!configuration.showTimeOnlyForActiveTask || isActiveTask)
        
        guard shouldShowTimeMarkers else { return }
        
        if taskDurationMinutes >= 40 {
            addFullTimeMarkers(&path, startAngle: startAngle, endAngle: endAngle)
        } else if taskDurationMinutes >= 20 {
            addThinTimeMarkers(&path, startAngle: startAngle, endAngle: endAngle)
        }
    }
    
    private func addFullTimeMarkers(_ path: inout Path, startAngle: Angle, endAngle: Angle) {
        let markerRadius = arcRadius + TaskArcConstants.timeTextOffset
        
        // Маркер начала
        let startMarkerPosition = timeMarkerPosition(for: startAngle)
        let startTimeText = DateFormatter.shortTime.string(from: task.startTime)
        let startMarkerWidth = CGFloat(startTimeText.count) * TaskArcConstants.timeMarkerCharacterWidth + TaskArcConstants.timeMarkerPadding
        
        path.addRoundedRect(
            in: CGRect(
                x: startMarkerPosition.x - startMarkerWidth/2,
                y: startMarkerPosition.y - TaskArcConstants.timeMarkerHeight/2,
                width: startMarkerWidth,
                height: TaskArcConstants.timeMarkerHeight
            ),
            cornerSize: CGSize(width: TaskArcConstants.timeMarkerHeight/2, height: TaskArcConstants.timeMarkerHeight/2)
        )
        
        // Маркер конца
        let endMarkerPosition = timeMarkerPosition(for: endAngle)
        let endTimeText = DateFormatter.shortTime.string(from: task.endTime)
        let endMarkerWidth = CGFloat(endTimeText.count) * TaskArcConstants.timeMarkerCharacterWidth + TaskArcConstants.timeMarkerPadding
        
        path.addRoundedRect(
            in: CGRect(
                x: endMarkerPosition.x - endMarkerWidth/2,
                y: endMarkerPosition.y - TaskArcConstants.timeMarkerHeight/2,
                width: endMarkerWidth,
                height: TaskArcConstants.timeMarkerHeight
            ),
            cornerSize: CGSize(width: TaskArcConstants.timeMarkerHeight/2, height: TaskArcConstants.timeMarkerHeight/2)
        )
    }
    
    private func addThinTimeMarkers(_ path: inout Path, startAngle: Angle, endAngle: Angle) {
        // Тонкие маркеры для коротких задач
        let startMarkerPosition = timeMarkerPosition(for: startAngle, isThin: true)
        let endMarkerPosition = timeMarkerPosition(for: endAngle, isThin: true)
        
        for position in [startMarkerPosition, endMarkerPosition] {
            path.addRoundedRect(
                in: CGRect(
                    x: position.x - TaskArcConstants.thinTimeMarkerWidth/2,
                    y: position.y - TaskArcConstants.thinTimeMarkerHeight/2,
                    width: TaskArcConstants.thinTimeMarkerWidth,
                    height: TaskArcConstants.thinTimeMarkerHeight
                ),
                cornerSize: CGSize(width: TaskArcConstants.thinTimeMarkerHeight/2, height: TaskArcConstants.thinTimeMarkerHeight/2)
            )
        }
    }
    
    // MARK: - Helper Properties
    var isActiveTask: Bool {
        let now = Date()
        return (task.startTime <= now && task.endTime > now) || configuration.isEditingMode
    }
    
    func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return degrees > 90 && degrees < 270
    }
} 

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
} 
