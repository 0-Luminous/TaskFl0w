//
// BottomBar.swift
// ToDoList
//
// Created by Yan on 21/3/25.

import SwiftUI

struct BottomBar: View {
    // MARK: - Properties
    let onAddTap: () -> Void
    let hapticsManager = HapticsManager.shared
    @Binding var isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    var onDeleteSelectedTasks: () -> Void
    var onChangePriorityForSelectedTasks: () -> Void
    var onArchiveTapped: () -> Void
    var onUnarchiveSelectedTasks: () -> Void
    @Binding var showCompletedTasksOnly: Bool
    
    // 🎯 НОВЫЕ ПАРАМЕТРЫ: Проверка наличия задач
    var hasArchivedTasks: Bool = true
    var hasActiveTasksForCurrentDay: Bool = true
    
    // Обновляем порядок обработчиков для дополнительных кнопок
    var onFlagSelectedTasks: () -> Void
    var onCalendarSelectedTasks: () -> Void
    var onChecklistSelectedTasks: () -> Void = {}

    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Добавляем состояние для отслеживания нажатий
    @State private var isAddButtonPressed = false
    
    // ДОБАВЛЯЕМ: состояния для анимации
    @State private var selectionButtonScale: CGFloat = 1.0
    @State private var selectionButtonRotation: Double = 0.0
    @State private var isSelectionButtonPressed = false
    @State private var pulseAnimation = false
    // ДОБАВЛЯЕМ: состояния для анимации кнопки выхода
    @State private var exitButtonScale: CGFloat = 1.0
    @State private var exitButtonRotation: Double = 0.0
    @State private var isExitButtonPressed = false
    @State private var exitPulseAnimation = false
    // ДОБАВЛЯЕМ: состояния для анимации архивной кнопки
    @State private var archiveButtonRotation: Double = 0.0
    @State private var isArchiveButtonPressed = false
    @State private var archivePulseAnimation = false

    // MARK: - Body
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                
                if !isSelectionMode {
                    HStack {
                        // 🎯 УСЛОВНОЕ ОТОБРАЖЕНИЕ: Показываем кнопку архива только если есть архивные задачи
                        if hasArchivedTasks {
                            ZStack {
                                Color.clear
                                archiveButton
                            }
                            
                            if hasActiveTasksForCurrentDay {
                                Spacer()
                                    .frame(width: 25)
                            }
                        }
                        
                        // 🎯 УСЛОВНОЕ ОТОБРАЖЕНИЕ: Показываем кнопку выбора только если есть задачи на текущий день
                        if hasActiveTasksForCurrentDay {
                            ZStack {
                                Color.clear
                                selectionModeToggleButton
                            }
                            
                            Spacer()
                                .frame(width: 25)
                        }
                        
                        ZStack {
                            Color.clear
                            addButton
                        }
                    }
                    // 🎯 ДИНАМИЧЕСКАЯ ШИРИНА: Адаптируется в зависимости от наличия кнопок
                    .frame(width: dynamicBottomBarWidth)
                } else {
                    HStack(spacing: 16) {

                        if !showCompletedTasksOnly {
                            ZStack {
                                Color.clear
                                calendarButton     
                            }
                        
                            ZStack {
                                Color.clear
                                flagButton
                            }
                            
                            ZStack {
                                Color.clear
                                exitSelectionModeButton
                            }

                            ZStack {
                                Color.clear
                                deleteButton
                            }

                            ZStack {
                                Color.clear
                                priorityButton
                            }
                        } else {
                            // Режим архива - кнопка архива слева
                            ZStack {
                                Color.clear
                                archiveActionButton
                            }
                            
                            ZStack {
                                Color.clear
                                exitSelectionModeButton
                            }

                            ZStack {
                                Color.clear
                                unarchiveButton
                            }
                        }
                        
                    }
                    .frame(width: showCompletedTasksOnly ? 180 : 308)
                }
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(height: 52)
            // 🎯 ДИНАМИЧЕСКАЯ МАКСИМАЛЬНАЯ ШИРИНА
            .frame(maxWidth: isSelectionMode 
                ? (showCompletedTasksOnly ? 240 : 340) 
                : dynamicMaxWidth)
            .background {
                ZStack {
                    // Размытый фон
                    Capsule()
                        .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95))
                    
                    // Добавляем градиентный бордер
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5),
                                    Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.3),
                                    Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Computed Properties для динамической ширины
    
    private var dynamicBottomBarWidth: CGFloat {
        let baseWidth: CGFloat = 65 // ширина кнопки Add + отступы
        var additionalWidth: CGFloat = 0
        
        if hasArchivedTasks {
            additionalWidth += 50 // ширина кнопки архива + отступ
        }
        
        if hasActiveTasksForCurrentDay {
            additionalWidth += 50 // ширина кнопки выбора + отступ
        }
        
        return baseWidth + additionalWidth
    }
    
    private var dynamicMaxWidth: CGFloat {
        let baseMaxWidth: CGFloat = 120 // базовая ширина для кнопки Add
        var additionalWidth: CGFloat = 0
        
        if hasArchivedTasks {
            additionalWidth += 50
        }
        
        if hasActiveTasksForCurrentDay {
            additionalWidth += 50
        }
        
        return baseMaxWidth + additionalWidth
    }
    
    // MARK: - UI Components
    
    private var archiveButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)) {
                isArchiveButtonPressed = true
                archiveButtonRotation += 360
            }
            
            hapticsManager.triggerMediumFeedback()
            
            // Добавляем задержку для visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    onArchiveTapped()
                    isArchiveButtonPressed = false
                }
            }
            
            // Запускаем пульсацию при переключении в архив
            withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
                archivePulseAnimation.toggle()
            }
        }) {
            animatedArchiveIcon
        }
        .rotationEffect(.degrees(archiveButtonRotation))
    }
    
    // Создаем отдельный компонент для анимированной архивной иконки
    private var animatedArchiveIcon: some View {
        ZStack {
            // Основная иконка
            Image(systemName: showCompletedTasksOnly ? "archivebox.fill" : "archivebox")
                .font(.system(size: 20, weight: showCompletedTasksOnly ? .bold : .regular))
                .foregroundStyle(
                    showCompletedTasksOnly 
                        ? LinearGradient(
                            gradient: Gradient(colors: [.purple, .indigo]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.isDarkMode ? .gray : .gray,
                                themeManager.isDarkMode ? .gray : .gray
                            ]),
                            startPoint: .center,
                            endPoint: .center
                        )
                )
                
            // Пульсирующий эффект при активации
            if showCompletedTasksOnly && archivePulseAnimation {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.6), .indigo.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(archivePulseAnimation ? 1.8 : 1.0)
                    .opacity(archivePulseAnimation ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 1.0), value: archivePulseAnimation)
            }
            
            // Дополнительные частицы при активации
            if showCompletedTasksOnly {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple.opacity(0.7), .indigo.opacity(0.4)]),
                                startPoint: .center,
                                endPoint: .center
                            )
                        )
                        .frame(width: 4, height: 2)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * (archivePulseAnimation ? 25 : 15),
                            y: sin(Double(index) * .pi / 3) * (archivePulseAnimation ? 25 : 15)
                        )
                        .opacity(archivePulseAnimation ? 0.0 : 0.8)
                        .scaleEffect(archivePulseAnimation ? 0.1 : 1.0)
                        .animation(
                            .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.1),
                            value: archivePulseAnimation
                        )
                }
            }
        }
        .padding(6)
        .background(
            Circle()
                .fill(
                    themeManager.isDarkMode 
                        ? Color(red: 0.184, green: 0.184, blue: 0.184)
                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                )
                .overlay(
                    Circle()
                        .stroke(
                            showCompletedTasksOnly
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.8),
                                        Color.indigo.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: showCompletedTasksOnly ? 2.0 : 1.0
                        )
                        // .scaleEffect(isArchiveButtonPressed ? 1.1 : 1.0)
                )
                .shadow(
                    color: showCompletedTasksOnly 
                        ? Color.purple.opacity(0.4) 
                        : Color.black.opacity(0.3),
                    radius: showCompletedTasksOnly ? 5 : 3,
                    x: 0,
                    y: 1
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showCompletedTasksOnly)
        .animation(.easeInOut(duration: 0.2), value: isArchiveButtonPressed)
    }
    
    private var selectionModeToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)) {
                isSelectionButtonPressed = true
                selectionButtonScale = 0.85
                selectionButtonRotation += 360
            }
            
            hapticsManager.triggerMediumFeedback()
            
            // Добавляем задержку для visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    toggleSelectionMode()
                    selectionButtonScale = 1.0
                    isSelectionButtonPressed = false
                }
            }
            
            // Запускаем пульсацию ТОЛЬКО при ВХОДЕ в режим селекции
            if !isSelectionMode {
                withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
                    pulseAnimation.toggle()
                }
            }
        }) {
            animatedSelectionIcon
        }
        .scaleEffect(selectionButtonScale)
        .rotationEffect(.degrees(selectionButtonRotation))
        .onAppear {
            // Небольшая задержка для smooth transition при появлении
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectionButtonScale = 1.0
                }
            }
        }
    }
    
    // Создаем отдельный компонент для анимированной иконки
    private var animatedSelectionIcon: some View {
        ZStack {
            // Основная иконка
            Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.system(size: 20, weight: isSelectionMode ? .bold : .regular))
                .foregroundStyle(
                    isSelectionMode 
                        ? LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [.gray, .gray]),
                            startPoint: .center,
                            endPoint: .center
                        )
                )
                .scaleEffect(isSelectionButtonPressed ? 1.2 : 1.0)
                
            // Пульсирующий эффект при активации
            if isSelectionMode && pulseAnimation {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(pulseAnimation ? 1.8 : 1.0)
                    .opacity(pulseAnimation ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 1.0), value: pulseAnimation)
            }
            
            // Дополнительные частицы при активации
            if isSelectionMode {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.7), .cyan.opacity(0.4)]),
                                startPoint: .center,
                                endPoint: .center
                            )
                        )
                        .frame(width: 3, height: 3)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * (pulseAnimation ? 25 : 15),
                            y: sin(Double(index) * .pi / 3) * (pulseAnimation ? 25 : 15)
                        )
                        .opacity(pulseAnimation ? 0.0 : 0.8)
                        .scaleEffect(pulseAnimation ? 0.1 : 1.0)
                        .animation(
                            .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.1),
                            value: pulseAnimation
                        )
                }
            }
        }
        .padding(6)
        .background(
            Circle()
                .fill(
                    themeManager.isDarkMode 
                        ? Color(red: 0.184, green: 0.184, blue: 0.184)
                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                )
                .overlay(
                    Circle()
                        .stroke(
                            isSelectionMode
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.8),
                                        Color.cyan.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelectionMode ? 2.0 : 1.0
                        )
                        .scaleEffect(isSelectionButtonPressed ? 1.1 : 1.0)
                )
                .shadow(
                    color: isSelectionMode 
                        ? Color.blue.opacity(0.4) 
                        : Color.black.opacity(0.3),
                    radius: isSelectionMode ? 5 : 3,
                    x: 0,
                    y: 1
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelectionMode)
        .animation(.easeInOut(duration: 0.2), value: isSelectionButtonPressed)
    }
    
    private var deleteButton: some View {
        Button(action: {
            hapticsManager.triggerMediumFeedback()
            onDeleteSelectedTasks()
        }) {
            toolbarIcon(systemName: "trash", color: .red)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var priorityButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                hapticsManager.triggerMediumFeedback()
                onChangePriorityForSelectedTasks()
            }
        }) {
            toolbarIcon(content: {
                priorityIconContent
            }, color: .gray)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    // Отображение иконки приоритета в виде столбцов
    private var priorityIconContent: some View {
        VStack(spacing: 2) {
            // Показываем три столбца для общей иконки приоритета
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 3)
            }
        }
        .frame(width: 24, height: 24)
    }
    
    private var exitSelectionModeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)) {
                isExitButtonPressed = true
                exitButtonScale = 0.8
                exitButtonRotation -= 360 // Обратное вращение для выхода
            }
            
            hapticsManager.triggerMediumFeedback()
            
            // Запускаем эффект "исчезновения" перед выходом
            withAnimation(.easeInOut(duration: 0.6).repeatCount(1, autoreverses: true)) {
                exitPulseAnimation.toggle()
            }
            
            // Добавляем задержку для visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    toggleSelectionMode()
                    exitButtonScale = 1.0
                    isExitButtonPressed = false
                }
            }
        }) {
            animatedExitIcon
        }
        .scaleEffect(exitButtonScale)
        .rotationEffect(.degrees(exitButtonRotation))
        .frame(width: 38, height: 38)
        .onAppear {
            // Анимация появления при входе в режим селекции
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                exitButtonScale = 1.0
            }
        }
    }
    
    // Создаем отдельный компонент для анимированной иконки выхода
    private var animatedExitIcon: some View {
        ZStack {
            // Основная иконка
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.isDarkMode ? .white : .black,
                            themeManager.isDarkMode ? .gray : .gray
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isExitButtonPressed ? 1.3 : 1.0)
                
            // Эффект "растворения" при выходе
            if exitPulseAnimation {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.6), 
                                Color.orange.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(exitPulseAnimation ? 2.2 : 1.0)
                    .opacity(exitPulseAnimation ? 0.0 : 0.9)
                    .animation(.easeOut(duration: 0.8), value: exitPulseAnimation)
            }
            
            // Частицы "разрушения" при выходе
            if exitPulseAnimation {
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8), 
                                    Color.orange.opacity(0.5)
                                ]),
                                startPoint: .center,
                                endPoint: .center
                            )
                        )
                        .frame(width: 2, height: 6)
                        .offset(
                            x: cos(Double(index) * .pi / 4) * (exitPulseAnimation ? 30 : 8),
                            y: sin(Double(index) * .pi / 4) * (exitPulseAnimation ? 30 : 8)
                        )
                        .rotationEffect(.degrees(Double(index) * 45))
                        .opacity(exitPulseAnimation ? 0.0 : 0.9)
                        .scaleEffect(exitPulseAnimation ? 0.1 : 1.0)
                        .animation(
                            .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.08),
                            value: exitPulseAnimation
                        )
                }
            }
            
            // Волновой эффект "выключения"
            if isExitButtonPressed {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.4),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .scaleEffect(isExitButtonPressed ? 1.5 : 0.5)
                    .opacity(isExitButtonPressed ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 0.6), value: isExitButtonPressed)
            }
        }
        .padding(6)
        .background(
            Circle()
                .fill(
                    themeManager.isDarkMode 
                        ? Color(red: 0.184, green: 0.184, blue: 0.184)
                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(exitPulseAnimation ? 0.8 : 0.4),
                                    Color.orange.opacity(exitPulseAnimation ? 0.6 : 0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isExitButtonPressed ? 2.5 : 1.5
                        )
                        .scaleEffect(isExitButtonPressed ? 1.2 : 1.0)
                )
                .shadow(
                    color: exitPulseAnimation 
                        ? Color.red.opacity(0.5) 
                        : Color.black.opacity(0.3),
                    radius: exitPulseAnimation ? 8 : 3,
                    x: 0,
                    y: 1
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: exitPulseAnimation)
        .animation(.easeInOut(duration: 0.3), value: isExitButtonPressed)
    }
    
    private var unarchiveButton: some View {
        Button(action: {
            hapticsManager.triggerMediumFeedback()
            onUnarchiveSelectedTasks()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "arrow.uturn.backward", color: .green)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var archiveActionButton: some View {
        Button(action: {
            hapticsManager.triggerMediumFeedback()
            onArchiveTapped()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "archivebox.fill", color: themeManager.isDarkMode ? .white : .black)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            if !showCompletedTasksOnly {
                hapticsManager.triggerMediumFeedback()
                onAddTap()
            }
        }) {
            toolbarIcon(systemName: "plus", color: themeManager.isDarkMode ? showCompletedTasksOnly ? .gray : .white : showCompletedTasksOnly ? .gray : .black)
        }
        .frame(width: 38, height: 38)
        .disabled(showCompletedTasksOnly)
        .opacity(showCompletedTasksOnly ? 0.5 : 1.0)
    }
    
    // Новые кнопки для режима выбора
    private var flagButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                hapticsManager.triggerMediumFeedback()
                onFlagSelectedTasks()
            }
        }) {
            toolbarIconWithGradient(
                systemName: "flag.fill", 
                gradient: LinearGradient(
                    gradient: Gradient(colors: [.red, .orange]), 
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var checklistButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                hapticsManager.triggerMediumFeedback()
                onChecklistSelectedTasks()
            }
        }) {
            toolbarIcon(systemName: "checklist", color: .green)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var calendarButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                hapticsManager.triggerMediumFeedback()
                onCalendarSelectedTasks()
            }
        }) {
            toolbarIconWithGradient(
                systemName: "calendar", 
                gradient: LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]), 
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelectionMode() {
        if isSelectionMode {
            selectedTasks.removeAll()
        }
        isSelectionMode.toggle()
    }
    
    private func toolbarIcon<Content: View>(content: @escaping () -> Content, color: Color) -> some View {
        content()
            .foregroundColor(color)
            .padding(6)
            .background(
                Circle()
                    .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
    }
    
    // Оригинальная версия toolbarIcon для других кнопок
    private func toolbarIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(color)
            .padding(6)
            .background(
                Circle()
                    .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
    }
    
    // Новая версия toolbarIcon для градиентов
    private func toolbarIconWithGradient(systemName: String, gradient: LinearGradient) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundStyle(gradient)
            .padding(6)
            .background(
                Circle()
                    .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
    }
}

