//
//  ClockViewState.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Combine

// MARK: - Clock View State
final class ClockViewState: ObservableObject {
    
    // MARK: - UI States
    @Published var previewTaskId: UUID?
    @Published var isDockBarEditingEnabled: Bool = false
    @Published var draggedTaskId: UUID?
    @Published var isDraggingOutside: Bool = false
    @Published var showingAddTask: Bool = false
    @Published var showingSettings: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var showingTodayTasks: Bool = false
    @Published var showingCategoryEditor: Bool = false
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""
    
    // MARK: - Editing States
    @Published var isEditingMode: Bool = false
    @Published var editingTaskId: UUID?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTaskId: UUID?
    
    // MARK: - Category States
    @Published var draggedCategoryId: UUID?
    @Published var selectedCategoryId: UUID?
    
    // MARK: - Computed Properties
    var isAnyModalPresented: Bool {
        showingAddTask || showingSettings || showingCalendar || 
        showingStatistics || showingTodayTasks || showingCategoryEditor || showingTaskDetail
    }
    
    var isDraggingAny: Bool {
        draggedTaskId != nil || draggedCategoryId != nil || isDraggingStart || isDraggingEnd
    }
    
    // MARK: - Methods
    func resetAllStates() {
        previewTaskId = nil
        isDockBarEditingEnabled = false
        draggedTaskId = nil
        isDraggingOutside = false
        showingAddTask = false
        showingSettings = false
        showingCalendar = false
        showingStatistics = false
        showingTodayTasks = false
        showingCategoryEditor = false
        showingTaskDetail = false
        searchText = ""
        isEditingMode = false
        editingTaskId = nil
        isDraggingStart = false
        isDraggingEnd = false
        previewTime = nil
        dropLocation = nil
        selectedTaskId = nil
        draggedCategoryId = nil
        selectedCategoryId = nil
    }
    
    func resetEditingStates() {
        isEditingMode = false
        editingTaskId = nil
        isDraggingStart = false
        isDraggingEnd = false
        previewTime = nil
        dropLocation = nil
        selectedTaskId = nil
    }
    
    func resetDragStates() {
        draggedTaskId = nil
        draggedCategoryId = nil
        isDraggingOutside = false
        isDraggingStart = false
        isDraggingEnd = false
        dropLocation = nil
    }
    
    func resetModalStates() {
        showingAddTask = false
        showingSettings = false
        showingCalendar = false
        showingStatistics = false
        showingTodayTasks = false
        showingCategoryEditor = false
        showingTaskDetail = false
    }
} 