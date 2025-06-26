//
//  ClockViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine

// MARK: - View States
struct MainViewState {
    var isSearchActive = false
    var isDockBarHidden = false
    var isOutsideArea = false
    var showingNewSettings = false
    var showingTaskTimeline = false
    var showingWeekCalendar = false
}

struct DragState {
    var offset: CGSize = .zero
    var isDragging = false
}

struct ZoomState {
    var scale: CGFloat = 1.0
    var focusOffset: CGPoint = .zero
}

// MARK: - Main View
struct ClockViewIOS: View {
    // MARK: - View Models
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var listViewModel: ListViewModel = {
        let context = PersistenceController.shared.container.viewContext
        let todoDataService = TodoDataService(context: context)
        let sharedStateService = SharedStateService()
        return ListViewModel(
            todoDataService: todoDataService,
            sharedStateService: sharedStateService
        )
    }()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // MARK: - Timer
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - View States
    @State private var clockState = MainViewState()
    @State private var dragState = DragState()
    @State private var zoomState = ZoomState()
    
    // MARK: - Subscriptions
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                mainContent
                overlayViews
            }
            .gesture(dragGesture)
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.userInteraction.showingCategoryEditor },
                set: { viewModel.userInteraction.showingCategoryEditor = $0 }
            )) {
                CategoryEditorViewIOS(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { viewModel.userInteraction.showingCategoryEditor },
                        set: { viewModel.userInteraction.showingCategoryEditor = $0 }
                    )
                )
            }
            .fullScreenCover(isPresented: $clockState.showingNewSettings) {
                NavigationStack {
                    PersonalizationViewIOS(viewModel: viewModel)
                }
            }
            .horizontalFullScreenCover(isPresented: $clockState.showingTaskTimeline) {
                TaskTimeline(
                    selectedDate: viewModel.selectedDate,
                    tasks: viewModel.tasks,
                    listViewModel: listViewModel,
                    categoryManager: viewModel.categoryManagement
                )
            }
            .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(timer) { _ in
            viewModel.updateCurrentTimeIfNeeded()
        }
        .onAppear {
            initializeUI()
            registerNotifications()
        }
        .onDisappear {
            unregisterNotifications()
        }
        .onChange(of: viewModel.userInteraction.isEditingMode) { _, _ in updateUI() }
        .onChange(of: viewModel.userInteraction.editingTask) { _, _ in updateUI() }
        .onChange(of: viewModel.userInteraction.previewTime) { _, _ in
            if viewModel.userInteraction.isEditingMode && (viewModel.userInteraction.isDraggingStart || viewModel.userInteraction.isDraggingEnd) {
                updateUI()
            }
        }
    }
    
    // MARK: - View Components
    private var backgroundView: some View {
        DropZoneView(
            isTargeted: $clockState.isOutsideArea,
            onEntered: handleDropZoneEntered,
            onExited: handleDropZoneExited
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if clockState.showingWeekCalendar {
                WeekCalendarView(
                    selectedDate: $viewModel.selectedDate,
                    onHideCalendar: { clockState.showingWeekCalendar = false }
                )
            }
            
            if viewModel.userInteraction.selectedCategory != nil {
                taskListView
            } else {
                clockFaceView
            }
        }
    }
    
    private var overlayViews: some View {
        ZStack {
            if !clockState.isSearchActive && !clockState.isDockBarHidden {
                VStack {
                    Spacer()
                    DockBarIOS(viewModel: viewModel.dockBarViewModel)
                        .transition(.move(edge: .bottom))
                }
            }
            
            if !clockState.showingWeekCalendar {
                VStack {
                    HeaderView(
                        viewModel: viewModel,
                        showSettingsAction: { clockState.showingNewSettings = true },
                        toggleCalendarAction: toggleWeekCalendar,
                        isCalendarVisible: clockState.showingWeekCalendar,
                        searchAction: handleSearch
                    )
                    Spacer()
                }
            }
        }
    }
    
    private var taskListView: some View {
        VStack(spacing: 0) {
            // Верхний Spacer только для режима списка задач
            Spacer()
                .frame(height: 20)
            
            TaskListView(
                selectedCategory: viewModel.userInteraction.selectedCategory,
                selectedDate: $viewModel.selectedDate,
                viewModel: listViewModel  // Уже использует TaskListViewModel
            )
            .background(themeManager.isDarkMode 
                ? Color(red: 0.098, green: 0.098, blue: 0.098) 
                : Color(red: 0.95, green: 0.95, blue: 0.95))
            .onAppear {
                listViewModel.selectedCategory = viewModel.userInteraction.selectedCategory
            }
            .onChange(of: viewModel.userInteraction.selectedCategory) { oldValue, newValue in
                listViewModel.selectedCategory = newValue
            }
            
            // Добавляем отступ снизу
            Spacer()
                .frame(height: 50)
        }
        .background(themeManager.isDarkMode 
            ? Color(red: 0.098, green: 0.098, blue: 0.098) 
            : Color(red: 0.95, green: 0.95, blue: 0.95))
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.userInteraction.selectedCategory)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 && value.startLocation.y < 100 {
                        dragState.isDragging = true
                        dragState.offset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 && value.startLocation.y < 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.userInteraction.selectedCategory = nil
                        }
                    }
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragState.isDragging = false
                        dragState.offset = .zero
                    }
                }
        )
    }
    
    private var clockFaceView: some View {
        ZStack {
            RingPlanner(
                color: ThemeManager.shared.currentOuterRingColor,
                viewModel: viewModel,
                zeroPosition: viewModel.timeManager.zeroPosition,
                shouldDeleteTask: false,
                outerRingLineWidth: viewModel.themeConfig.outerRingLineWidth
            )

            GlobleClockFaceViewIOS(
                currentDate: viewModel.selectedDate,
                tasks: viewModel.tasks,
                viewModel: viewModel,
                markersViewModel: viewModel.markersViewModel,
                draggedCategory: Binding(
                    get: { viewModel.userInteraction.draggedCategory },
                    set: { viewModel.userInteraction.draggedCategory = $0 }
                ),
                zeroPosition: viewModel.timeManager.zeroPosition,
                taskArcLineWidth: viewModel.themeConfig.isAnalogArcStyle ? viewModel.themeConfig.outerRingLineWidth : viewModel.themeConfig.taskArcLineWidth,
                outerRingLineWidth: viewModel.themeConfig.outerRingLineWidth
            )

            if viewModel.userInteraction.isEditingMode, let editingTask = viewModel.userInteraction.editingTask {
                TimeTaskEditorOverlay(
                    viewModel: viewModel,
                    task: editingTask
                )
            }
            
            if zoomState.scale > 1.01 {
                VStack {
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -50)
        .offset(x: dragState.offset.width < 0 ? dragState.offset.width : 0)
        .offset(x: zoomState.focusOffset.x, y: zoomState.focusOffset.y)
        .scaleEffect(zoomState.scale)
        .animation(.spring(), value: dragState.isDragging)
        .animation(.spring(), value: zoomState.scale)
        .animation(.spring(), value: zoomState.focusOffset)
    }
    
    // MARK: - Event Handlers
    private func handleDropZoneEntered() {
        print("⚠️ [ClockViewIOS] Объект перетаскивания обнаружен во внешней зоне")
        if let task = viewModel.userInteraction.draggedTask {
            print("⚠️ [ClockViewIOS] Это задача \(task.id) - запускаем анимированное удаление")
            startTaskRemovalAnimation(for: task)
        }
    }
    
    private func startTaskRemovalAnimation(for task: TaskOnRing) {
        // Отправляем уведомление для запуска анимации исчезновения
        NotificationCenter.default.post(
            name: .startTaskRemovalAnimation,
            object: self,
            userInfo: ["task": task]
        )
    }
    
    private func handleDropZoneExited() {
        print("⚠️ [ClockViewIOS] Объект покинул внешнюю зону")
    }
    
    private func handleSearch() {
        // Реализация поиска
    }
    
    // MARK: - Helper Functions
    private func toggleWeekCalendar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            clockState.showingWeekCalendar.toggle()
        }
    }
    
    private func initializeUI() {
        viewModel.markersViewModel.numbersSize = viewModel.themeConfig.numbersSize
        viewModel.updateUIForThemeChange()
        viewModel.updateMarkersViewModel()
    }
    
    private func updateUI() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if viewModel.userInteraction.isEditingMode, let task = viewModel.userInteraction.editingTask {
                let (scale, offset) = calculateZoomScale(for: task)
                zoomState.scale = scale
                zoomState.focusOffset = offset
            } else {
                zoomState.scale = 1.0
                zoomState.focusOffset = .zero
            }
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("SearchActiveStateChanged"))
            .compactMap { notification -> Bool? in
                notification.userInfo?["isActive"] as? Bool
            }
            .receive(on: DispatchQueue.main)
            .sink { isActive in
                withAnimation(.easeInOut(duration: 0.2)) {
                    clockState.isSearchActive = isActive
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("DockBarVisibilityChanged"))
            .compactMap { notification -> Bool? in
                notification.userInfo?["isVisible"] as? Bool
            }
            .receive(on: DispatchQueue.main)
            .sink { isVisible in
                withAnimation(.easeInOut(duration: 0.2)) {
                    clockState.isDockBarHidden = !isVisible
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CloseTaskTimeline"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                withAnimation {
                    clockState.showingTaskTimeline = false
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("ClockStyleDidChange"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.viewModel.applyWatchFaceSettings()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("WatchFaceApplied"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.viewModel.applyWatchFaceSettings()
            }
            .store(in: &cancellables)
    }
    
    private func unregisterNotifications() {
        cancellables.removeAll()
    }
    
    private func calculateZoomScale(for task: TaskOnRing) -> (scale: CGFloat, offset: CGPoint) {
        let durationHours = task.duration / 3600
        
        if durationHours >= 1 {
            return (1.0, .zero)
        }
        
        let minDuration: Double = 10 * 60
        let maxDuration: Double = 1 * 3600
        let minScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.7
        
        let limitedDuration = max(minDuration, task.duration)
        let normalizedDuration = 1 - ((limitedDuration - minDuration) / (maxDuration - minDuration))
        let scale = minScale + normalizedDuration * (maxScale - minScale)
        
        let startAngle = viewModel.timeToAngle(task.startTime)
        let endAngle = viewModel.timeToAngle(task.endTime)
        let midAngle = (startAngle + endAngle) / 2.0
        let midAngleRadians = midAngle * .pi / 180.0
        
        let approximateRadius: CGFloat = 150
        let scaleFactor = scale - 1.0
        let offsetX = cos(midAngleRadians) * approximateRadius * scaleFactor
        let offsetY = sin(midAngleRadians) * approximateRadius * scaleFactor
        
        return (scale, CGPoint(x: offsetX, y: offsetY))
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragGesture(value)
            }
            .onEnded { value in
                handleDragGestureEnd(value)
            }
    }
    
    private func handleDragGesture(_ value: DragGesture.Value) {
        if value.translation.width < 0 && !clockState.showingWeekCalendar && !viewModel.userInteraction.isEditingMode {
            dragState.isDragging = true
            dragState.offset = value.translation
        }
    }
    
    private func handleDragGestureEnd(_ value: DragGesture.Value) {
        if value.translation.width < -100 && !clockState.showingWeekCalendar && !viewModel.userInteraction.isEditingMode {
            withAnimation {
                clockState.showingTaskTimeline = true
            }
        }
        
        withAnimation(.spring()) {
            dragState.isDragging = false
            dragState.offset = .zero
        }
    }
}

#Preview {
    ClockViewIOS()
}
