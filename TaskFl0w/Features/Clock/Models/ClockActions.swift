//
//  ClockActions.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import SwiftUI
import Foundation

// MARK: - Main Clock Actions
enum ClockAction {
    case time(TimeAction)
    case tasks(TasksAction)
    case ui(UIAction)
    case theme(ThemeAction)
}

// MARK: - Time Actions
enum TimeAction {
    case updateCurrentTime(Date)
    case selectDate(Date)
    case updateZeroPosition(Double)
}

// MARK: - Tasks Actions
enum TasksAction {
    case loadTasks
    case addTask(TaskOnRing)
    case updateTask(TaskOnRing)
    case removeTask(TaskOnRing)
    case setPreviewTask(TaskOnRing?)
    case searchTasks(String)
    case validateOverlaps
    case setLoading(Bool)
    case setError(String?)
    case updateTasksForDate(Date)
}

// MARK: - UI Actions
enum UIAction {
    // Modal actions
    case showAddTask
    case hideAddTask
    case showSettings
    case hideSettings
    case showCalendar
    case hideCalendar
    case showStatistics
    case hideStatistics
    case showTodayTasks
    case hideTodayTasks
    case showCategoryEditor
    case hideCategoryEditor
    case showTaskDetail
    case hideTaskDetail
    
    // Task selection
    case selectTask(TaskOnRing?)
    case startEditingTask(TaskOnRing)
    case finishEditingTask
    
    // Drag & Drop
    case startDragging(TaskOnRing)
    case stopDragging(Bool)
    case updateDragPosition(Bool, CGPoint?)
    case selectCategory(TaskCategoryModel?)
    case startDraggingCategory(TaskCategoryModel)
    case stopDraggingCategory
    case updatePreviewTime(Date?)
    
    // Edit mode
    case enableEditMode
    case disableEditMode
    case enableDockBarEditing
    case disableDockBarEditing
    case resetAllStates
    case resetDragStates
}

// MARK: - Theme Actions  
enum ThemeAction {
    case setDarkMode(Bool)
    case updateClockStyle(String)
    case setNotificationsEnabled(Bool)
    case setShowTimeOnlyForActiveTask(Bool)
    case setAnalogArcStyle(Bool)
    
    // Color updates
    case updateLightModeHandColor(String)
    case updateDarkModeHandColor(String)
    case updateLightModeDigitalFontColor(String)
    case updateDarkModeDigitalFontColor(String)
    case updateLightModeClockFaceColor(String)
    case updateDarkModeClockFaceColor(String)
    case updateLightModeOuterRingColor(String)
    case updateDarkModeOuterRingColor(String)
    case updateLightModeMarkersColor(String)
    case updateDarkModeMarkersColor(String)
    
    // Dimension updates
    case updateTaskArcLineWidth(CGFloat)
    case updateOuterRingLineWidth(CGFloat)
    
    // Marker updates
    case setShowHourNumbers(Bool)
    case updateMarkersWidth(Double)
    case updateMarkersOffset(Double)
    case updateNumbersSize(Double)
    case updateNumberInterval(Int)
    case setShowMarkers(Bool)
    case setShowIntermediateMarkers(Bool)
    
    // Font updates
    case updateDigitalFont(String)
    case updateFontName(String)
    case updateDigitalFontSize(Double)
    case updateMarkerStyle(MarkerStyle)
    
    // Bulk updates
    case resetToDefaults
    case applyWatchFaceSettings
} 