//
//  TaskArcShape.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import CoreGraphics
import SwiftUI

struct TaskArcShape: View {
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    let hapticsManager: HapticsManager
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        ZStack {
            geometry.createArcPath()
                .stroke(
                    geometry.task.category.color,
                    lineWidth: geometry.configuration.arcLineWidth
                )

            if shouldShowTimeMarkersInPreview {
                TaskTimeMarkersForPreview(
                    task: geometry.task,
                    geometry: geometry,
                    timeFormatter: timeFormatter,
                    viewModel: viewModel
                )
            }

            if shouldShowIcon {
                TaskIcon(
                    task: geometry.task,
                    geometry: geometry,
                    animationManager: animationManager,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    viewModel: viewModel
                )
            }
        }
        .contentShape(.interaction, geometry.createGestureArea())
        .contentShape(.dragPreview, createCustomDragPreview())
    }

    private func createCustomDragPreview() -> some Shape {
        let shouldStartMarkerBeThin = shouldMarkerBeThin(for: geometry.task.startTime)
        let shouldEndMarkerBeThin = shouldMarkerBeThin(for: geometry.task.endTime)

        return CustomDragPreviewShape(
            geometry: geometry,
            startMarkerThin: shouldStartMarkerBeThin,
            endMarkerThin: shouldEndMarkerBeThin
        )
    }

    private var shouldShowTimeMarkersInPreview: Bool {
        !geometry.configuration.isAnalog && !geometry.configuration.isEditingMode
            && geometry.taskDurationMinutes >= 20
    }

    private var shouldShowIcon: Bool {
        return true
    }

    private func shouldMarkerBeThin(for markerTime: Date) -> Bool {
        guard geometry.taskDurationMinutes >= 20 else { return false }

        if geometry.taskDurationMinutes < 40 {
            return true
        }
        return hasNearbyTasksWithThinMarkers(for: markerTime)
    }

    private func hasNearbyTasksWithThinMarkers(for markerTime: Date) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != geometry.task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60
            let otherTaskHasThinMarkers = determineIfTaskHasThinMarkers(
                otherTask, otherTaskDuration)

            if otherTaskHasThinMarkers {
                let proximityToStart = abs(markerTime.timeIntervalSince(otherTask.startTime))
                let proximityToEnd = abs(markerTime.timeIntervalSince(otherTask.endTime))

                if proximityToStart <= proximityThreshold || proximityToEnd <= proximityThreshold {
                    return true
                }
            }
        }

        return false
    }

    private func determineIfTaskHasThinMarkers(_ task: TaskOnRing, _ durationMinutes: Double)
        -> Bool
    {
        if durationMinutes >= 20 && durationMinutes < 40 {
            return true
        }

        if durationMinutes >= 40 {
            return checkIfLongTaskHasThinMarkers(task)
        }
        return false
    }

    private func checkIfLongTaskHasThinMarkers(_ task: TaskOnRing) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60

            if otherTaskDuration >= 20 && otherTaskDuration < 40 {
                let startToStartProximity = abs(
                    task.startTime.timeIntervalSince(otherTask.startTime))
                let endToEndProximity = abs(task.endTime.timeIntervalSince(otherTask.endTime))
                let startToEndProximity = abs(task.startTime.timeIntervalSince(otherTask.endTime))
                let endToStartProximity = abs(task.endTime.timeIntervalSince(otherTask.startTime))

                if startToStartProximity <= proximityThreshold
                    || endToEndProximity <= proximityThreshold
                    || startToEndProximity <= proximityThreshold
                    || endToStartProximity <= proximityThreshold
                {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Supporting Views
struct TaskTimeMarkersForPreview: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        let (startAngle, endAngle) = geometry.angles
        let startTimeText = timeFormatter.string(from: task.startTime)
        let endTimeText = timeFormatter.string(from: task.endTime)

        let shouldStartMarkerBeThin = shouldMarkerBeThin(for: task.startTime)
        let shouldEndMarkerBeThin = shouldMarkerBeThin(for: task.endTime)

        if geometry.taskDurationMinutes >= 40 {
            TaskTimeLabelForPreview(
                text: shouldStartMarkerBeThin ? "" : startTimeText,
                angle: startAngle,
                geometry: geometry,
                isThin: shouldStartMarkerBeThin,
                viewModel: viewModel
            )

            TaskTimeLabelForPreview(
                text: shouldEndMarkerBeThin ? "" : endTimeText,
                angle: endAngle,
                geometry: geometry,
                isThin: shouldEndMarkerBeThin,
                viewModel: viewModel
            )
        } else if geometry.taskDurationMinutes >= 20 {
            TaskTimeLabelForPreview(
                text: "",
                angle: startAngle,
                geometry: geometry,
                isThin: true,
                viewModel: viewModel
            )

            TaskTimeLabelForPreview(
                text: "",
                angle: endAngle,
                geometry: geometry,
                isThin: true,
                viewModel: viewModel
            )
        }
    }

    private func shouldMarkerBeThin(for markerTime: Date) -> Bool {
        guard geometry.taskDurationMinutes >= 20 else { return false }

        if geometry.taskDurationMinutes < 40 {
            return true
        }

        return hasNearbyTasksWithThinMarkers(for: markerTime)
    }

    private func hasNearbyTasksWithThinMarkers(for markerTime: Date) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60
            let otherTaskHasThinMarkers = determineIfTaskHasThinMarkers(
                otherTask, otherTaskDuration)

            if otherTaskHasThinMarkers {
                let proximityToStart = abs(markerTime.timeIntervalSince(otherTask.startTime))
                let proximityToEnd = abs(markerTime.timeIntervalSince(otherTask.endTime))

                if proximityToStart <= proximityThreshold || proximityToEnd <= proximityThreshold {
                    return true
                }
            }
        }

        return false
    }

    private func determineIfTaskHasThinMarkers(_ task: TaskOnRing, _ durationMinutes: Double)
        -> Bool
    {
        if durationMinutes >= 20 && durationMinutes < 40 {
            return true
        }

        if durationMinutes >= 40 {
            return checkIfLongTaskHasThinMarkers(task)
        }

        return false
    }

    private func checkIfLongTaskHasThinMarkers(_ task: TaskOnRing) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60

            if otherTaskDuration >= 20 && otherTaskDuration < 40 {
                let startToStartProximity = abs(
                    task.startTime.timeIntervalSince(otherTask.startTime))
                let endToEndProximity = abs(task.endTime.timeIntervalSince(otherTask.endTime))
                let startToEndProximity = abs(task.startTime.timeIntervalSince(otherTask.endTime))
                let endToStartProximity = abs(task.endTime.timeIntervalSince(otherTask.startTime))

                if startToStartProximity <= proximityThreshold
                    || endToEndProximity <= proximityThreshold
                    || startToEndProximity <= proximityThreshold
                    || endToStartProximity <= proximityThreshold
                {
                    return true
                }
            }
        }

        return false
    }
}

struct TaskTimeLabelForPreview: View {
    let text: String
    let angle: Angle
    let geometry: TaskArcGeometry
    let isThin: Bool
    let viewModel: ClockViewModel?

    private var markerTime: Date {
        let (startAngle, endAngle) = geometry.angles
        let isStartMarker =
            abs(angle.degrees - startAngle.degrees) < abs(angle.degrees - endAngle.degrees)
        return isStartMarker ? geometry.task.startTime : geometry.task.endTime
    }

    private var touchingTasks: [TaskOnRing] {
        guard let viewModel = viewModel else { return [] }

        let proximityThreshold: TimeInterval = 15 * 60  // 15 минут
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != geometry.task.id }

        return otherTasks.filter { otherTask in
            let startProximity = abs(markerTime.timeIntervalSince(otherTask.startTime))
            let endProximity = abs(markerTime.timeIntervalSince(otherTask.endTime))

            return startProximity <= proximityThreshold || endProximity <= proximityThreshold
        }
    }

    private var markerFill: AnyShapeStyle {
        if touchingTasks.isEmpty {
            return AnyShapeStyle(geometry.task.category.color)
        } else {
            var colors: [Color] = [geometry.task.category.color]
            colors.append(contentsOf: touchingTasks.map { $0.category.color })

            let uniqueColors = Array(Set(colors.map { $0.description }))
                .compactMap { colorDescription in
                    colors.first { $0.description == colorDescription }
                }

            if uniqueColors.count > 1 {
                return AnyShapeStyle(
                    LinearGradient(
                        gradient: Gradient(colors: uniqueColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                return AnyShapeStyle(geometry.task.category.color)
            }
        }
    }

    var body: some View {
        let isLeftHalf = geometry.isAngleInLeftHalf(angle)
        let scale: CGFloat = 1.0

        ZStack {
            Capsule()
                .fill(markerFill)
                .frame(
                    width: isThin
                        ? TaskArcConstants.thinTimeMarkerWidth
                        : CGFloat(text.count) * TaskArcConstants.timeMarkerCharacterWidth
                            + TaskArcConstants.timeMarkerPadding,
                    height: isThin
                        ? TaskArcConstants.thinTimeMarkerHeight : TaskArcConstants.timeMarkerHeight
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)

            if !isThin {
                Text(text)
                    .font(.system(size: TaskArcConstants.timeFontSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
        .position(geometry.timeMarkerPosition(for: angle, isThin: isThin))
        .scaleEffect(scale)
        .animation(.none, value: angle)
    }
}

struct TaskIcon: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: HapticsManager
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        ZStack {
            Circle()
                .fill(task.category.color)
                .frame(width: backgroundSize, height: backgroundSize)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            if shouldShowDragIndicator {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(rotationAngleToCenter)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            } else {
                Image(systemName: task.category.iconName)
                    .font(.system(size: geometry.iconFontSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            }
        }
        .position(currentPosition)
        .scaleEffect(iconScale)
        .opacity(animationManager.appearanceOpacity)
        .rotationEffect(.degrees(animationManager.appearanceRotation * 0.5))
        .animation(
            .easeInOut(duration: TaskArcConstants.appearanceAnimationDuration),
            value: geometry.configuration.editingOffset
        )
        .animation(.none, value: currentPosition)
        .gesture(shouldShowDragIndicator ? createWholeArcDragGesture() : nil)
    }

    // MARK: - Computed Properties
    private var backgroundSize: CGFloat {
        shouldShowDragIndicator ? geometry.iconSize * 1.4 : geometry.iconSize
    }

    private var shouldShowDragIndicator: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id
    }

    private var currentPosition: CGPoint {
        if gestureHandler.isDraggingWholeArc && shouldShowDragIndicator {
            let currentAngles = RingTimeCalculator.calculateAngles(for: geometry.task)
            let currentMidAngle = RingTimeCalculator.calculateMidAngle(
                start: currentAngles.start, end: currentAngles.end)
            let midAngleRadians = currentMidAngle.radians

            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius) * cos(midAngleRadians),
                y: geometry.center.y + (geometry.iconRadius) * sin(midAngleRadians)
            )
        } else if shouldShowDragIndicator {
            let basePosition = geometry.iconPosition()
            let angle = atan2(
                basePosition.y - geometry.center.y, basePosition.x - geometry.center.x)

            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius) * cos(angle),
                y: geometry.center.y + (geometry.iconRadius) * sin(angle)
            )
        } else {
            return geometry.iconPosition()
        }
    }

    private var rotationAngleToCenter: Angle {
        let iconPos = currentPosition
        let center = geometry.center

        let deltaX = center.x - iconPos.x
        let deltaY = center.y - iconPos.y
        let angleToCenter = atan2(deltaY, deltaX)

        return Angle(radians: angleToCenter + .pi / 2)
    }

    private var iconScale: CGFloat {
        animationManager.appearanceScale * TaskArcConstants.iconScaleMultiplier
            * (animationManager.isPressed ? TaskArcConstants.pressScale : 1.0)
    }

    // MARK: - Gesture Handling
    private func createWholeArcDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !gestureHandler.isDraggingWholeArc {
                    gestureHandler.startWholeArcDrag(
                        at: value.startLocation,
                        center: geometry.center,
                        indicatorPosition: currentPosition
                    )
                    hapticsManager.triggerLightFeedback()
                }

                gestureHandler.handleWholeArcDrag(value: value, center: geometry.center)
            }
            .onEnded { _ in
                gestureHandler.finalizeWholeArcDrag()
                gestureHandler.isDraggingWholeArc = false
                gestureHandler.resetLastHourComponent()
                hapticsManager.triggerSoftFeedback()
            }
    }
}

struct CustomDragPreviewShape: Shape {
    let geometry: TaskArcGeometry
    let startMarkerThin: Bool
    let endMarkerThin: Bool

    func path(in rect: CGRect) -> Path {
        return geometry.createDragPreviewArea(
            startMarkerThin: startMarkerThin, endMarkerThin: endMarkerThin)
    }
}

struct TaskTimeMarkers: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        let (startAngle, endAngle) = geometry.angles
        let startTimeText = timeFormatter.string(from: task.startTime)
        let endTimeText = timeFormatter.string(from: task.endTime)

        let shouldStartMarkerBeThin = shouldMarkerBeThin(for: task.startTime)
        let shouldEndMarkerBeThin = shouldMarkerBeThin(for: task.endTime)

        if geometry.taskDurationMinutes >= 40 {
            TaskTimeLabelForPreview(
                text: shouldStartMarkerBeThin ? "" : startTimeText,
                angle: startAngle,
                geometry: geometry,
                isThin: shouldStartMarkerBeThin,
                viewModel: viewModel
            )

            TaskTimeLabelForPreview(
                text: shouldEndMarkerBeThin ? "" : endTimeText,
                angle: endAngle,
                geometry: geometry,
                isThin: shouldEndMarkerBeThin,
                viewModel: viewModel
            )
        } else if geometry.taskDurationMinutes >= 20 {
            TaskTimeLabelForPreview(
                text: "",
                angle: startAngle,
                geometry: geometry,
                isThin: true,
                viewModel: viewModel
            )

            TaskTimeLabelForPreview(
                text: "",
                angle: endAngle,
                geometry: geometry,
                isThin: true,
                viewModel: viewModel
            )
        }
    }

    private func shouldMarkerBeThin(for markerTime: Date) -> Bool {
        guard geometry.taskDurationMinutes >= 20 else { return false }

        if geometry.taskDurationMinutes < 40 {
            return true
        }

        return hasNearbyTasksWithThinMarkers(for: markerTime)
    }

    private func hasNearbyTasksWithThinMarkers(for markerTime: Date) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60

        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)

        let otherTasks = tasksForDate.filter { $0.id != task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60  // в минутах

            let otherTaskHasThinMarkers = determineIfTaskHasThinMarkers(
                otherTask, otherTaskDuration)

            if otherTaskHasThinMarkers {
                let proximityToStart = abs(markerTime.timeIntervalSince(otherTask.startTime))
                let proximityToEnd = abs(markerTime.timeIntervalSince(otherTask.endTime))

                if proximityToStart <= proximityThreshold || proximityToEnd <= proximityThreshold {
                    return true
                }
            }
        }

        return false
    }

    private func determineIfTaskHasThinMarkers(_ task: TaskOnRing, _ durationMinutes: Double)
        -> Bool
    {
        if durationMinutes >= 20 && durationMinutes < 40 {
            return true
        }

        if durationMinutes >= 40 {
            return checkIfLongTaskHasThinMarkers(task)
        }

        return false
    }

    private func checkIfLongTaskHasThinMarkers(_ task: TaskOnRing) -> Bool {
        let proximityThreshold: TimeInterval = 15 * 60
        let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
        let otherTasks = tasksForDate.filter { $0.id != task.id }

        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60

            if otherTaskDuration >= 20 && otherTaskDuration < 40 {
                let startToStartProximity = abs(
                    task.startTime.timeIntervalSince(otherTask.startTime))
                let endToEndProximity = abs(task.endTime.timeIntervalSince(otherTask.endTime))
                let startToEndProximity = abs(task.startTime.timeIntervalSince(otherTask.endTime))
                let endToStartProximity = abs(task.endTime.timeIntervalSince(otherTask.startTime))

                if startToStartProximity <= proximityThreshold
                    || endToEndProximity <= proximityThreshold
                    || startToEndProximity <= proximityThreshold
                    || endToStartProximity <= proximityThreshold
                {
                    return true
                }
            }
        }

        return false
    }
}
