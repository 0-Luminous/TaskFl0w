//
//  DockBarViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//

import SwiftUI

@MainActor
final class DockBarViewModel: ObservableObject {
    // MARK: - Services
    let categoryManagement: CategoryManagementProtocol
    
    // MARK: - Published properties
    @Published var showingAddTask: Bool = false
    @Published var draggedCategory: TaskCategoryModel?
    @Published var showingCategoryEditor: Bool = false
    @Published var selectedCategory: TaskCategoryModel?
    @Published var editingCategory: TaskCategoryModel?
    
    @Published var isEditMode: Bool = false
    @Published var currentPage: Int = 0
    @Published var lastNonEditPage: Int = 0
    
    // MARK: - Constants
    let categoriesPerPage = 4
    let categoryWidth: CGFloat = 80
    
    // MARK: - Computed properties
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }
    
    var visibleCategories: [TaskCategoryModel] {
        categories.filter { !$0.isHidden }
    }
    
    var numberOfPages: Int {
        let count = visibleCategories.count
        return max((count + categoriesPerPage - 1) / categoriesPerPage, 1)
    }
    
    var pageWithAddButton: Int {
        // Если у нас ровно 4 категории или больше, кнопка добавления должна быть на второй странице
        return visibleCategories.count >= categoriesPerPage ? 1 : 0
    }
    
    // MARK: - Initialization
    init(categoryManagement: CategoryManagementProtocol) {
        self.categoryManagement = categoryManagement
    }
    
    // MARK: - Category methods
    func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        let startIndex = page * categoriesPerPage
        guard startIndex < visibleCategories.count else { return [] }
        let endIndex = min(startIndex + categoriesPerPage, visibleCategories.count)
        return Array(visibleCategories[startIndex..<endIndex])
    }
    
    func shouldShowAddButton(on page: Int) -> Bool {
        if !isEditMode { return false }
        
        // Для 4 или более категорий показываем кнопку на второй странице
        if visibleCategories.count >= categoriesPerPage {
            return page == 1
        }
        
        // Для менее 4 категорий показываем на первой странице
        return page == 0
    }
    
    func isEditing(_ category: TaskCategoryModel) -> Bool {
        return editingCategory?.id == category.id
    }
    
    func deleteCategory(_ category: TaskCategoryModel) {
        categoryManagement.removeCategory(category)
    }
    
    func moveCategory(from source: Int, to destination: Int) {
        guard let draggedCategory = draggedCategory else { return }
        
        print("📦 DEBUG: moveCategory called - from: \(source), to: \(destination)")
        
        // Вызываем метод перемещения категории
        categoryManagement.moveCategory(from: source, to: destination)
        
        // Сбрасываем состояние перетаскивания
        print("🔄 DEBUG: Clearing draggedCategory after category move")
        self.draggedCategory = nil
    }
    
    // Добавляем новый метод для явного сброса
    func clearDraggedCategory() {
        print("🔄 DEBUG: clearDraggedCategory called")
        self.draggedCategory = nil
    }
    
    // MARK: - UI Feedback
    func triggerHapticFeedback() {
        #if os(iOS)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        #endif
    }
    
    // MARK: - Edit mode
    func toggleEditMode() {
        triggerHapticFeedback()
        
        if !isEditMode {
            lastNonEditPage = currentPage
        }
        isEditMode.toggle()
        
        if isEditMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showingCategoryEditor = true
                self.isEditMode = false
            }
        }
    }
    
    // MARK: - Helpers for UI
    func backgroundColorForTheme(in colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9)
    }
    
    func shadowColorForTheme(in colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

// MARK: - Вспомогательные типы для поддержки DragDrop
extension DockBarViewModel {
    struct CategoryDropDelegate: DropDelegate {
        let item: TaskCategoryModel
        let items: [TaskCategoryModel]
        let draggedItem: TaskCategoryModel?
        let moveAction: (Int, Int) -> Void
        
        func performDrop(info: DropInfo) -> Bool {
            guard let draggedItem = draggedItem else { return false }
            
            let fromIndex = items.firstIndex(of: draggedItem) ?? 0
            let toIndex = items.firstIndex(of: item) ?? 0
            
            if fromIndex != toIndex {
                moveAction(fromIndex, toIndex)
            }
            
            return true
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }
        
        func validateDrop(info: DropInfo) -> Bool {
            return true
        }
    }
}

