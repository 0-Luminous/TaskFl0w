//
//  ClockState.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import SwiftUI
import Foundation

// MARK: - Main Clock State
struct ClockState {
    var time = TimeState()
    var tasks = TasksState()
    var ui = ClockUIState()
    var theme = ThemeState()
}

// MARK: - Time State
struct TimeState {
    var currentDate = Date()
    var selectedDate = Date()
    var zeroPosition: Double = 0
}

// MARK: - Tasks State  
struct TasksState {
    var tasks: [Any] = []
    var overlappingTaskGroups: [[Any]] = []
    var previewTask: Any?
    var searchText = ""
    var isLoading = false
    var error: String?
}

// MARK: - Clock UI State
struct ClockUIState {
    // Modal States
    var showingAddTask = false
    var showingSettings = false
    var showingCalendar = false
    var showingStatistics = false
    var showingTodayTasks = false
    var showingCategoryEditor = false
    var showingTaskDetail = false
    
    // Task Management
    var selectedTask: Any?
    var editingTask: Any?
    var draggedTask: Any?
    var draggedCategory: Any?
    var selectedCategory: Any?
    
    // Edit Mode
    var isEditingMode = false
    var isDraggingOutside = false
    var isDraggingStart = false
    var isDraggingEnd = false
    var previewTime: Date?
    var dropLocation: CGPoint?
    var isDockBarEditingEnabled = false
}

// MARK: - Theme State
struct ThemeState {
    var isDarkMode = false
    var clockStyle = "Классический"
    
    // Notifications
    var notificationsEnabled = true
    var showTimeOnlyForActiveTask = false
    var isAnalogArcStyle = false
    
    // Colors
    var lightModeHandColor = "#007AFF"
    var darkModeHandColor = "#007AFF"
    var lightModeDigitalFontColor = "#8E8E93"
    var darkModeDigitalFontColor = "#FFFFFF"
    var lightModeClockFaceColor = "#FFFFFF"
    var darkModeClockFaceColor = "#000000"
    var lightModeOuterRingColor = "#8E8E934D"
    var darkModeOuterRingColor = "#8E8E934D"
    var lightModeMarkersColor = "#8E8E93"
    var darkModeMarkersColor = "#8E8E93"
    
    // Dimensions
    var taskArcLineWidth: CGFloat = 20
    var outerRingLineWidth: CGFloat = 20
    
    // Markers
    var showHourNumbers = true
    var markersWidth: Double = 2.0
    var markersOffset: Double = 0.0
    var numbersSize: Double = 16.0
    var numberInterval = 1
    var showMarkers = true
    var showIntermediateMarkers = true
    
    // Fonts
    var digitalFont = "SF Pro"
    var fontName = "SF Pro"
    var digitalFontSize: Double = 42.0
    var markerStyle = "lines"
} 