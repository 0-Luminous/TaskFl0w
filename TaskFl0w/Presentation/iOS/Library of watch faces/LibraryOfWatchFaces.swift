//
//  LibraryOfWatchFaces.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Добавляем перечисление для категорий циферблатов
enum WatchFaceCategory: String, CaseIterable, Identifiable {
    case classic = "Классический"
    case digital = "Цифровой"
    case minimal = "Минимализм"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .classic: return "clock"
        case .digital: return "123.rectangle"
        case .minimal: return "circle.slash"
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
            // Цифровой циферблат
            WatchFaceModel(
                name: "Мегаполис",
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.black.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.8).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.8).toHex(),
                lightModeMarkersColor: Color.gray.toHex(),
                darkModeMarkersColor: Color.gray.toHex(),
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
        return watchFaces.filter { $0.category == category.rawValue }
    }
    
    // Создание пользовательского циферблата из текущих настроек
    func createCustomWatchFace(name: String) {
        let themeManager = ThemeManager.shared
        
        // Определяем стиль часов
        let style = UserDefaults.standard.string(forKey: "clockStyle") ?? "classic"
        
        // Определяем категорию на основе стиля
        let category: String
        if style.contains("minimal") {
            category = WatchFaceCategory.minimal.rawValue
        } else if style.contains("digital") {
            category = WatchFaceCategory.digital.rawValue
        } else {
            category = WatchFaceCategory.classic.rawValue
        }
        
        let newFace = WatchFaceModel(
            name: name,
            style: style,
            isCustom: true,
            category: category,
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
    
    // Модификатор для стилизации кнопок
    private struct ButtonModifier: ViewModifier {
        let isSelected: Bool
        let isDisabled: Bool
        
        init(isSelected: Bool = false, isDisabled: Bool = false) {
            self.isSelected = isSelected
            self.isDisabled = isDisabled
        }
        
        func body(content: Content) -> some View {
            content
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(isSelected ? .yellow : (isDisabled ? .gray : .white))
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color(red: 0.184, green: 0.184, blue: 0.184)
                              .opacity(isDisabled ? 0.5 : 1))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(isDisabled ? 0.3 : 0.7),
                                    Color.gray.opacity(isDisabled ? 0.1 : 0.3),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isDisabled ? 0.5 : 1.0
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                .opacity(isDisabled ? 0.6 : 1)
        }
    }
    
    // Модификатор для кнопок действий
    private struct ActionButtonModifier: ViewModifier {
        let color: Color
        
        func body(content: Content) -> some View {
            content
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    Text("Библиотека циферблатов")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                        .padding(.bottom, 12)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Отображаем каждую категорию с её циферблатами
                            ForEach(WatchFaceCategory.allCases) { category in
                                EnhancedCategorySection(
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
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top)
                    }
                    
                    Spacer()
                }
                
                // Нижняя панель с кнопками
                VStack {
                    Spacer()
                    
                    HStack(spacing: 15) {
                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Создать")
                            }
                            .modifier(ActionButtonModifier(color: Color.blue))
                        }
                        
                        Button {
                            showDeleteAllAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Сбросить")
                            }
                            .modifier(ActionButtonModifier(color: Color.red))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .background(
                        Rectangle()
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: -4)
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EnhancedAddWatchFaceView()
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                selectedWatchFace = nil
            }) {
                if let face = selectedWatchFace {
                    EnhancedEditWatchFaceView(watchFace: face)
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

// Улучшенная секция для категории циферблатов
struct EnhancedCategorySection: View {
    let category: WatchFaceCategory
    let watchFaces: [WatchFaceModel]
    let libraryManager: WatchFaceLibraryManager
    let onWatchFaceSelected: (WatchFaceModel) -> Void
    let onEdit: (WatchFaceModel) -> Void
    let onDelete: (WatchFaceModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок категории
            HStack {
                Image(systemName: category.systemImage)
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
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
                            EnhancedWatchFacePreviewCard(
                                watchFace: face, 
                                isSelected: libraryManager.selectedFaceID == face.id
                            )
                            .onTapGesture {
                                onWatchFaceSelected(face)
                            }
                            .contextMenu {
                                if face.isCustom {
                                    Button {
                                        onEdit(face)
                                    } label: {
                                        Label("Редактировать", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        onDelete(face)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
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
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal)
        }
    }
}

// Улучшенная карточка для предпросмотра циферблата
struct EnhancedWatchFacePreviewCard: View {
    let watchFace: WatchFaceModel
    let isSelected: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @State private var draggedCategory: TaskCategoryModel? = nil
    
    var body: some View {
        VStack {
            // Миниатюра циферблата
            ZStack {
                // Фон карточки
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .shadow(color: isSelected ? .yellow.opacity(0.4) : .black.opacity(0.5), radius: 5)
                
                VStack {
                    // Предпросмотр циферблата
                    ZStack {
                        // Внешнее кольцо
                        Circle()
                            .stroke(
                                colorScheme == .dark 
                                    ? Color(hex: watchFace.darkModeOuterRingColor) ?? .gray 
                                    : Color(hex: watchFace.lightModeOuterRingColor) ?? .gray,
                                lineWidth: watchFace.outerRingLineWidth * 0.35
                            )
                            .frame(width: 110, height: 110)
                        
                        // Используем GlobleClockFaceViewIOS для отображения циферблата
                        GlobleClockFaceViewIOS(
                            currentDate: Date(),
                            tasks: [],
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            draggedCategory: $draggedCategory,
                            zeroPosition: watchFace.zeroPosition,
                            taskArcLineWidth: watchFace.taskArcLineWidth,
                            outerRingLineWidth: watchFace.outerRingLineWidth
                        )
                        .scaleEffect(0.35)
                        .frame(width: 120, height: 120)
                    }
                    .padding(.top, 12)
                    
                    // Название и статус
                    VStack(spacing: 2) {
                        Text(watchFace.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if watchFace.isCustom {
                            Text("Пользовательский")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 160, height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected 
                        ? LinearGradient(
                            colors: [.yellow, .yellow.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .onAppear {
            setupViewModels()
        }
    }
    
    private func setupViewModels() {
        // Настройка цветов и параметров для предпросмотра
        markersViewModel.showMarkers = watchFace.showMarkers
        markersViewModel.showHourNumbers = watchFace.showHourNumbers
        markersViewModel.numberInterval = watchFace.numberInterval
        markersViewModel.markersOffset = watchFace.markersOffset
        markersViewModel.markersWidth = watchFace.markersWidth
        markersViewModel.numbersSize = watchFace.numbersSize
        markersViewModel.lightModeMarkersColor = watchFace.lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = watchFace.darkModeMarkersColor
        markersViewModel.isDarkMode = colorScheme == .dark
        markersViewModel.updateCurrentThemeColors()
        
        // Настройка ClockViewModel без присваивания markersViewModel
        viewModel.clockStyle = watchFace.style
        viewModel.zeroPosition = watchFace.zeroPosition
        viewModel.outerRingLineWidth = watchFace.outerRingLineWidth
        viewModel.taskArcLineWidth = watchFace.taskArcLineWidth
        viewModel.isAnalogArcStyle = watchFace.isAnalogArcStyle
        
        // Вместо прямого присваивания markersViewModel
        // Синхронизируем настройки маркеров напрямую
        viewModel.showHourNumbers = markersViewModel.showHourNumbers
        viewModel.markersWidth = markersViewModel.markersWidth
        viewModel.markersOffset = markersViewModel.markersOffset
        viewModel.numbersSize = markersViewModel.numbersSize
        viewModel.numberInterval = markersViewModel.numberInterval
        viewModel.lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        viewModel.darkModeMarkersColor = markersViewModel.darkModeMarkersColor
    }
}

// Улучшенный экран добавления циферблата
struct EnhancedAddWatchFaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @State private var watchFaceName = ""
    
    // Модификатор для текстового поля
    private struct TextFieldModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Название циферблата", text: $watchFaceName)
                        .modifier(TextFieldModifier())
                    
                    // Предпросмотр текущего циферблата
                    Text("Предпросмотр")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Text("Текущий циферблат")
                                .foregroundColor(.white)
                        )
                        .padding(.bottom, 20)
                    
                    Text("Сохраните текущие настройки как новый пользовательский циферблат")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        if !watchFaceName.isEmpty {
                            libraryManager.createCustomWatchFace(name: watchFaceName)
                            dismiss()
                        }
                    } label: {
                        Text("Сохранить")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                !watchFaceName.isEmpty
                                    ? LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(watchFaceName.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("Новый циферблат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Отмена")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// Улучшенный экран редактирования циферблата
struct EnhancedEditWatchFaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    
    let watchFace: WatchFaceModel
    @State private var editedName: String
    @State private var showingDeleteAlert = false
    
    init(watchFace: WatchFaceModel) {
        self.watchFace = watchFace
        _editedName = State(initialValue: watchFace.name)
    }
    
    // Модификатор для текстового поля
    private struct TextFieldModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Название циферблата", text: $editedName)
                        .modifier(TextFieldModifier())
                    
                    // Предпросмотр циферблата
                    Text("Предпросмотр")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    EnhancedWatchFacePreviewCard(watchFace: watchFace, isSelected: true)
                        .scaleEffect(1.2)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Кнопка удаления
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Удалить циферблат")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Кнопка сохранения
                    Button {
                        if !editedName.isEmpty {
                            var updatedFace = watchFace
                            updatedFace.name = editedName
                            libraryManager.updateWatchFace(updatedFace)
                            dismiss()
                        }
                    } label: {
                        Text("Сохранить")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                !editedName.isEmpty
                                    ? LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(editedName.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Отмена")
                        }
                        .foregroundColor(.white)
                    }
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
        }
    }
}

// MARK: - Расширение для предпросмотра в SwiftUI
struct LibraryOfWatchFaces_Previews: PreviewProvider {
    static var previews: some View {
        LibraryOfWatchFaces()
    }
}

