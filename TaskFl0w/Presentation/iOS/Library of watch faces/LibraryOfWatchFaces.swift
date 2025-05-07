//
//  LibraryOfWatchFaces.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Добавляем перечисление для категорий циферблатов
enum WatchFaceCategory: String, CaseIterable, Identifiable {
    case classic = "Классические"
    case minimal = "Минималистичные"
    case creative = "Креативные"
    case custom = "Мои циферблаты"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .classic: return "clock"
        case .minimal: return "circle.slash"
        case .creative: return "paintpalette"
        case .custom: return "person"
        }
    }
}

// MARK: - Модель циферблата
struct WatchFaceModel: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var style: String // Используем String, чтобы легко хранить в UserDefaults
    var isCustom: Bool = false
    var category: String = WatchFaceCategory.classic.rawValue
    
    // Цвета в формате HEX для сохранения
    var lightModeClockFaceColor: String
    var darkModeClockFaceColor: String
    var lightModeOuterRingColor: String
    var darkModeOuterRingColor: String
    var lightModeMarkersColor: String
    var darkModeMarkersColor: String
    
    // Настройки маркеров
    var showMarkers: Bool = true
    var showHourNumbers: Bool = true
    var numberInterval: Int = 1
    var markersOffset: Double = 0.0
    var markersWidth: Double = 2.0
    var numbersSize: Double = 16.0
    
    // Дополнительные настройки
    var zeroPosition: Double = 0.0 // Угол поворота 0 часов
    var outerRingLineWidth: CGFloat = 20.0
    var taskArcLineWidth: CGFloat = 20.0
    var isAnalogArcStyle: Bool = false
    
    static func == (lhs: WatchFaceModel, rhs: WatchFaceModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Предустановленные циферблаты
    static var defaultWatchFaces: [WatchFaceModel] {
        [
            // Классический светлый циферблат
            WatchFaceModel(
                name: "Классический",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color.white.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex()
            ),
            // Добавляем еще один классический циферблат
            WatchFaceModel(
                name: "Капучино",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.95, green: 0.95, blue: 0.87).toHex(),
                darkModeClockFaceColor: Color(red: 0.15, green: 0.15, blue: 0.12).toHex(),
                lightModeOuterRingColor: Color.brown.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.brown.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.brown.toHex(),
                darkModeMarkersColor: Color.brown.opacity(0.7).toHex()
            ),
            // Минималистичный циферблат
            WatchFaceModel(
                name: "Чистый",
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color.white.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.2).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.2).toHex(),
                lightModeMarkersColor: Color.gray.toHex(),
                darkModeMarkersColor: Color.gray.toHex(),
                showHourNumbers: false
            ),
            // Креативный циферблат
            WatchFaceModel(
                name: "Неоновый",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.creative.rawValue,
                lightModeClockFaceColor: Color.black.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.green.opacity(0.8).toHex(),
                darkModeOuterRingColor: Color.green.opacity(0.8).toHex(),
                lightModeMarkersColor: Color.green.toHex(),
                darkModeMarkersColor: Color.green.toHex(),
                showHourNumbers: true, 
                numberInterval: 2
            )
        ]
    }
    
    // Метод для применения циферблата
    func apply(to themeManager: ThemeManager) {
        // Устанавливаем цвета
        themeManager.updateColor(Color(hex: lightModeClockFaceColor) ?? .white, 
                                  for: ThemeManager.Constants.lightModeClockFaceColorKey)
        themeManager.updateColor(Color(hex: darkModeClockFaceColor) ?? .black, 
                                 for: ThemeManager.Constants.darkModeClockFaceColorKey)
        themeManager.updateColor(Color(hex: lightModeOuterRingColor) ?? .gray.opacity(0.3), 
                                 for: ThemeManager.Constants.lightModeOuterRingColorKey)
        themeManager.updateColor(Color(hex: darkModeOuterRingColor) ?? .gray.opacity(0.3), 
                                 for: ThemeManager.Constants.darkModeOuterRingColorKey)
        themeManager.updateColor(Color(hex: lightModeMarkersColor) ?? .black, 
                                 for: ThemeManager.Constants.lightModeMarkersColorKey)
        themeManager.updateColor(Color(hex: darkModeMarkersColor) ?? .white, 
                                 for: ThemeManager.Constants.darkModeMarkersColorKey)
        
        // Сохраняем настройки в UserDefaults
        UserDefaults.standard.set(style, forKey: "clockStyle")
        UserDefaults.standard.set(showMarkers, forKey: "showMarkers")
        UserDefaults.standard.set(showHourNumbers, forKey: "showHourNumbers")
        UserDefaults.standard.set(numberInterval, forKey: "numberInterval")
        UserDefaults.standard.set(markersOffset, forKey: "markersOffset")
        UserDefaults.standard.set(markersWidth, forKey: "markersWidth")
        UserDefaults.standard.set(numbersSize, forKey: "numbersSize")
        UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
        UserDefaults.standard.set(outerRingLineWidth, forKey: "outerRingLineWidth")
        UserDefaults.standard.set(taskArcLineWidth, forKey: "taskArcLineWidth")
        UserDefaults.standard.set(isAnalogArcStyle, forKey: "isAnalogArcStyle")
    }
}

// MARK: - Менеджер библиотеки циферблатов
class WatchFaceLibraryManager: ObservableObject {
    // Синглтон для доступа к менеджеру из любого места
    static let shared = WatchFaceLibraryManager()
    
    // Публикуемые свойства
    @Published var watchFaces: [WatchFaceModel] = []
    @Published var selectedFaceID: UUID?
    
    // Ключи для UserDefaults
    private let watchFacesKey = "storedWatchFaces"
    private let selectedFaceIDKey = "selectedWatchFaceID"
    
    private init() {
        loadWatchFaces()
        
        // Если библиотека пуста, добавляем предустановленные циферблаты
        if watchFaces.isEmpty {
            watchFaces = WatchFaceModel.defaultWatchFaces
            saveWatchFaces()
        }
        
        // Загружаем выбранный циферблат
        if let storedIDString = UserDefaults.standard.string(forKey: selectedFaceIDKey),
           let storedID = UUID(uuidString: storedIDString) {
            selectedFaceID = storedID
        } else {
            // Если ничего не выбрано, выбираем первый циферблат
            selectedFaceID = watchFaces.first?.id
        }
    }
    
    // Получение текущего выбранного циферблата
    var currentWatchFace: WatchFaceModel? {
        guard let selectedID = selectedFaceID else { return nil }
        return watchFaces.first(where: { $0.id == selectedID })
    }
    
    // Получить циферблаты по категории
    func watchFaces(for category: WatchFaceCategory) -> [WatchFaceModel] {
        if category == .custom {
            return watchFaces.filter { $0.isCustom }
        } else {
            return watchFaces.filter { $0.category == category.rawValue && !$0.isCustom }
        }
    }
    
    // Создание пользовательского циферблата из текущих настроек
    func createCustomWatchFace(name: String) {
        let themeManager = ThemeManager.shared
        
        let newFace = WatchFaceModel(
            name: name,
            style: UserDefaults.standard.string(forKey: "clockStyle") ?? "classic",
            isCustom: true,
            category: WatchFaceCategory.custom.rawValue,
            lightModeClockFaceColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.lightModeClockFaceColorKey) ?? Color.white.toHex(),
            darkModeClockFaceColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.darkModeClockFaceColorKey) ?? Color.black.toHex(),
            lightModeOuterRingColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.lightModeOuterRingColorKey) ?? Color.gray.opacity(0.3).toHex(),
            darkModeOuterRingColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.darkModeOuterRingColorKey) ?? Color.gray.opacity(0.3).toHex(),
            lightModeMarkersColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.lightModeMarkersColorKey) ?? Color.black.toHex(),
            darkModeMarkersColor: UserDefaults.standard.string(forKey: ThemeManager.Constants.darkModeMarkersColorKey) ?? Color.white.toHex(),
            showMarkers: UserDefaults.standard.bool(forKey: "showMarkers"),
            showHourNumbers: UserDefaults.standard.bool(forKey: "showHourNumbers"),
            numberInterval: UserDefaults.standard.integer(forKey: "numberInterval"),
            markersOffset: UserDefaults.standard.double(forKey: "markersOffset"),
            markersWidth: UserDefaults.standard.double(forKey: "markersWidth"),
            numbersSize: UserDefaults.standard.double(forKey: "numbersSize"),
            zeroPosition: UserDefaults.standard.double(forKey: "zeroPosition"),
            outerRingLineWidth: CGFloat(UserDefaults.standard.double(forKey: "outerRingLineWidth")),
            taskArcLineWidth: CGFloat(UserDefaults.standard.double(forKey: "taskArcLineWidth")),
            isAnalogArcStyle: UserDefaults.standard.bool(forKey: "isAnalogArcStyle")
        )
        
        watchFaces.append(newFace)
        selectedFaceID = newFace.id
        saveWatchFaces()
    }
    
    // Выбор циферблата
    func selectWatchFace(_ faceID: UUID) {
        if let face = watchFaces.first(where: { $0.id == faceID }) {
            selectedFaceID = faceID
            UserDefaults.standard.set(faceID.uuidString, forKey: selectedFaceIDKey)
            
            // Применяем настройки циферблата
            face.apply(to: ThemeManager.shared)
        }
    }
    
    // Удаление циферблата
    func deleteWatchFace(_ faceID: UUID) {
        // Удаляем только пользовательские циферблаты
        if let index = watchFaces.firstIndex(where: { $0.id == faceID && $0.isCustom }) {
            watchFaces.remove(at: index)
            
            // Если удаляем выбранный циферблат, выбираем первый доступный
            if selectedFaceID == faceID {
                selectedFaceID = watchFaces.first?.id
                if let face = watchFaces.first {
                    face.apply(to: ThemeManager.shared)
                }
            }
            
            saveWatchFaces()
        }
    }
    
    // Обновление пользовательского циферблата
    func updateWatchFace(_ updatedFace: WatchFaceModel) {
        if let index = watchFaces.firstIndex(where: { $0.id == updatedFace.id }) {
            watchFaces[index] = updatedFace
            saveWatchFaces()
            
            // Если обновляем выбранный циферблат, применяем его настройки
            if selectedFaceID == updatedFace.id {
                updatedFace.apply(to: ThemeManager.shared)
            }
        }
    }
    
    // Сохранение циферблатов в UserDefaults
    private func saveWatchFaces() {
        if let encodedData = try? JSONEncoder().encode(watchFaces) {
            UserDefaults.standard.set(encodedData, forKey: watchFacesKey)
        }
    }
    
    // Загрузка циферблатов из UserDefaults
    private func loadWatchFaces() {
        if let savedData = UserDefaults.standard.data(forKey: watchFacesKey),
           let decodedFaces = try? JSONDecoder().decode([WatchFaceModel].self, from: savedData) {
            watchFaces = decodedFaces
        } else {
            watchFaces = []
        }
    }
    
    // Удаление всех циферблатов
    func clearAllWatchFaces() {
        // Создаем новый массив только с предустановленными циферблатами
        let defaultFaces = WatchFaceModel.defaultWatchFaces
        watchFaces = defaultFaces
        
        // Выбираем первый циферблат как активный
        selectedFaceID = defaultFaces.first?.id
        if let firstFace = defaultFaces.first {
            firstFace.apply(to: ThemeManager.shared)
        }
        
        // Сохраняем изменения
        saveWatchFaces()
        UserDefaults.standard.set(selectedFaceID?.uuidString, forKey: selectedFaceIDKey)
    }
}

// MARK: - Просмотр библиотеки циферблатов
struct LibraryOfWatchFaces: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var newWatchFaceName = ""
    @State private var selectedWatchFace: WatchFaceModel?
    @State private var showDeleteAllAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Отображаем каждую категорию с её циферблатами
                    ForEach(WatchFaceCategory.allCases) { category in
                        CategorySection(
                            category: category,
                            watchFaces: libraryManager.watchFaces(for: category),
                            libraryManager: libraryManager,
                            onWatchFaceSelected: { face in
                                libraryManager.selectWatchFace(face.id)
                                dismiss()
                            },
                            onEdit: { face in
                                selectedWatchFace = face
                                showingEditSheet = true
                            },
                            onDelete: { face in
                                libraryManager.deleteWatchFace(face.id)
                            }
                        )
                    }
                    
                    Spacer().frame(height: 80) // Дополнительное пространство внизу
                }
                .padding(.top)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Создать циферблат")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button {
                        showDeleteAllAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Сбросить всё")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
                )
            }
            .navigationTitle("Библиотека циферблатов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWatchFaceView()
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                selectedWatchFace = nil
            }) {
                if let face = selectedWatchFace {
                    EditWatchFaceView(watchFace: face)
                }
            }
            .alert("Сбросить библиотеку?", isPresented: $showDeleteAllAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Сбросить", role: .destructive) {
                    libraryManager.clearAllWatchFaces()
                }
            } message: {
                Text("Будут удалены все пользовательские циферблаты и восстановлены предустановленные. Это действие нельзя отменить.")
            }
        }
    }
}

// Секция для категории циферблатов
struct CategorySection: View {
    let category: WatchFaceCategory
    let watchFaces: [WatchFaceModel]
    let libraryManager: WatchFaceLibraryManager
    let onWatchFaceSelected: (WatchFaceModel) -> Void
    let onEdit: (WatchFaceModel) -> Void
    let onDelete: (WatchFaceModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Заголовок категории
            HStack {
                Image(systemName: category.systemImage)
                    .font(.headline)
                Text(category.rawValue)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            if watchFaces.isEmpty {
                Text("Нет циферблатов в этой категории")
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            } else {
                // Горизонтальный скролл циферблатов
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(watchFaces) { face in
                            WatchFacePreviewCard(watchFace: face)
                                .onTapGesture {
                                    onWatchFaceSelected(face)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            libraryManager.selectedFaceID == face.id ? Color.blue : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .contextMenu {
                                    if face.isCustom {
                                        Button(role: .destructive) {
                                            onDelete(face)
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            onEdit(face)
                                        } label: {
                                            Label("Редактировать", systemImage: "pencil")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
            
            Divider()
                .padding(.horizontal)
        }
    }
}

// MARK: - Карточка для предпросмотра циферблата
struct WatchFacePreviewCard: View {
    let watchFace: WatchFaceModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @State private var draggedCategory: TaskCategoryModel? = nil
    
    var body: some View {
        VStack {
            // Миниатюра циферблата
            ZStack {
                // Добавляем RingPlanner для отображения внешнего кольца
                RingPlanner(
                    color: colorScheme == .dark ? Color(hex: watchFace.darkModeOuterRingColor) ?? .gray : Color(hex: watchFace.lightModeOuterRingColor) ?? .gray,
                    viewModel: viewModel,
                    zeroPosition: watchFace.zeroPosition,
                    shouldDeleteTask: false,
                    outerRingLineWidth: watchFace.outerRingLineWidth
                )
                .scaleEffect(0.35)
                .frame(width: 120, height: 120)
                
                // Используем GlobleClockFaceViewIOS для отображения циферблата
                GlobleClockFaceViewIOS(
                    currentDate: Date(),
                    tasks: [],  // Пустой массив задач для предпросмотра
                    viewModel: viewModel,
                    markersViewModel: markersViewModel,
                    draggedCategory: $draggedCategory,
                    zeroPosition: watchFace.zeroPosition,
                    taskArcLineWidth: watchFace.taskArcLineWidth,
                    outerRingLineWidth: watchFace.outerRingLineWidth
                )
                .scaleEffect(0.35)  // Масштабируем для миниатюры
                .frame(width: 120, height: 120)
            }
            
            Text(watchFace.name)
                .font(.headline)
                .lineLimit(1)
            
            if watchFace.isCustom {
                Text("Пользовательский")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .frame(width: 160, height: 180)
        .onAppear {
            // Настраиваем ViewModel и MarkersViewModel на основе параметров циферблата
            setupViewModels()
        }
    }
    
    private func setupViewModels() {
        // Настройка цветов
        let lightModeClockFaceColor = Color(hex: watchFace.lightModeClockFaceColor) ?? .white
        let darkModeClockFaceColor = Color(hex: watchFace.darkModeClockFaceColor) ?? .black
        let lightModeMarkersColor = Color(hex: watchFace.lightModeMarkersColor) ?? .black
        let darkModeMarkersColor = Color(hex: watchFace.darkModeMarkersColor) ?? .white
        
        // Обновляем цвета в ThemeManager для правильного отображения
        ThemeManager.shared.updateColor(lightModeClockFaceColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
        ThemeManager.shared.updateColor(darkModeClockFaceColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
        ThemeManager.shared.updateColor(lightModeMarkersColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
        ThemeManager.shared.updateColor(darkModeMarkersColor, for: ThemeManager.Constants.darkModeMarkersColorKey)
        
        // Настройка MarkersViewModel
        markersViewModel.showMarkers = watchFace.showMarkers
        markersViewModel.showHourNumbers = watchFace.showHourNumbers
        markersViewModel.numberInterval = watchFace.numberInterval
        markersViewModel.markersOffset = watchFace.markersOffset
        markersViewModel.markersWidth = watchFace.markersWidth
        markersViewModel.numbersSize = watchFace.numbersSize
        markersViewModel.zeroPosition = watchFace.zeroPosition
        markersViewModel.isDarkMode = colorScheme == .dark
        
        // Настройка ClockViewModel
        viewModel.zeroPosition = watchFace.zeroPosition
        viewModel.outerRingLineWidth = watchFace.outerRingLineWidth
        viewModel.taskArcLineWidth = watchFace.taskArcLineWidth
        viewModel.isAnalogArcStyle = watchFace.isAnalogArcStyle
    }
}

// Упрощенная компонента стрелок часов для предпросмотра
struct ClockHandPreview: View {
    let date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let centerY = height / 2
            
            ZStack {
                // Часовая стрелка
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: width * 0.25)
                    .offset(y: -(width * 0.25) / 2)
                    .position(x: centerX, y: centerY)
                    .rotationEffect(hourAngle)
                
                // Минутная стрелка
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 1.5, height: width * 0.35)
                    .offset(y: -(width * 0.35) / 2)
                    .position(x: centerX, y: centerY)
                    .rotationEffect(minuteAngle)
                
                // Центральная точка
                Circle()
                    .fill(Color.primary)
                    .frame(width: 5, height: 5)
                    .position(x: centerX, y: centerY)
            }
        }
    }
    
    // Угол для часовой стрелки
    private var hourAngle: Angle {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date) % 12)
        let minute = Double(calendar.component(.minute, from: date))
        let hourAngle = (hour + minute / 60.0) / 12.0 * 360.0
        return .degrees(hourAngle)
    }
    
    // Угол для минутной стрелки
    private var minuteAngle: Angle {
        let calendar = Calendar.current
        let minute = Double(calendar.component(.minute, from: date))
        return .degrees(minute / 60.0 * 360.0)
    }
}

// MARK: - Экран добавления нового циферблата
struct AddWatchFaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @State private var watchFaceName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Название циферблата", text: $watchFaceName)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Text("Сохраните текущие настройки циферблата как новый пользовательский циферблат")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Новый циферблат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if !watchFaceName.isEmpty {
                            libraryManager.createCustomWatchFace(name: watchFaceName)
                            dismiss()
                        }
                    }
                    .disabled(watchFaceName.isEmpty)
                }
            }
            .padding(.top)
        }
    }
}

// MARK: - Экран редактирования циферблата
struct EditWatchFaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    
    let watchFace: WatchFaceModel
    @State private var editedName: String
    @State private var showingDeleteAlert = false
    
    init(watchFace: WatchFaceModel) {
        self.watchFace = watchFace
        _editedName = State(initialValue: watchFace.name)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Название циферблата", text: $editedName)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Spacer()
                
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Удалить циферблат")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if !editedName.isEmpty {
                            var updatedFace = watchFace
                            updatedFace.name = editedName
                            libraryManager.updateWatchFace(updatedFace)
                            dismiss()
                        }
                    }
                    .disabled(editedName.isEmpty)
                }
            }
            .alert("Удалить циферблат?", isPresented: $showingDeleteAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    libraryManager.deleteWatchFace(watchFace.id)
                    dismiss()
                }
            } message: {
                Text("Действие нельзя отменить")
            }
            .padding(.top)
        }
    }
}

// MARK: - Расширение для предпросмотра в SwiftUI
struct LibraryOfWatchFaces_Previews: PreviewProvider {
    static var previews: some View {
        LibraryOfWatchFaces()
    }
}

