//
//  WatchFaceLibraryManager.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

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
        
        // Загружаем выбранный циферблат из UserDefaults, но не выбираем автоматически
        // при открытии библиотеки
        if let storedIDString = UserDefaults.standard.string(forKey: selectedFaceIDKey),
           let storedID = UUID(uuidString: storedIDString) {
            selectedFaceID = storedID
        }
        // Удаляем автоматический выбор первого циферблата
        // else {
        //    selectedFaceID = watchFaces.first?.id
        // }
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
        let russianStyle = UserDefaults.standard.string(forKey: "clockStyle") ?? "Классический"
        let style = WatchFaceModel.internalStyleName(for: russianStyle)
        
        // Определяем категорию на основе стиля
        let category: String
        
        if style == "minimal" {
            category = WatchFaceCategory.minimal.rawValue
        } else if style == "digital" {
            category = WatchFaceCategory.digital.rawValue
        } else {
            category = WatchFaceCategory.classic.rawValue
        }
        
        // Получаем цвета стрелки из UserDefaults
        let lightModeHandColor = UserDefaults.standard.string(forKey: "lightModeHandColor") ?? Color.blue.toHex()
        let darkModeHandColor = UserDefaults.standard.string(forKey: "darkModeHandColor") ?? Color.blue.toHex()
        
        // Берем цвета напрямую из ThemeManager вместо UserDefaults
        let newFace = WatchFaceModel(
            name: name,
            nameKey: nil, // Для пользовательских циферблатов nameKey = nil
            style: style,
            isCustom: true,
            category: category,
            lightModeClockFaceColor: themeManager.currentClockFaceColor.toHex(),
            darkModeClockFaceColor: themeManager.currentClockFaceColor.toHex(),
            lightModeOuterRingColor: themeManager.currentOuterRingColor.toHex(),
            darkModeOuterRingColor: themeManager.currentOuterRingColor.toHex(),
            lightModeMarkersColor: themeManager.currentMarkersColor.toHex(),
            darkModeMarkersColor: themeManager.currentMarkersColor.toHex(),
            showMarkers: UserDefaults.standard.bool(forKey: "showMarkers"),
            showHourNumbers: UserDefaults.standard.bool(forKey: "showHourNumbers"),
            numberInterval: UserDefaults.standard.integer(forKey: "numberInterval"),
            markersOffset: UserDefaults.standard.double(forKey: "markersOffset"),
            markersWidth: UserDefaults.standard.double(forKey: "markersWidth"),
            numbersSize: UserDefaults.standard.double(forKey: "numbersSize"),
            markerStyle: UserDefaults.standard.string(forKey: "markerStyle") ?? "standard",
            showIntermediateMarkers: UserDefaults.standard.bool(forKey: "showIntermediateMarkers"),
            zeroPosition: UserDefaults.standard.double(forKey: "zeroPosition"),
            outerRingLineWidth: CGFloat(UserDefaults.standard.double(forKey: "outerRingLineWidth")),
            taskArcLineWidth: CGFloat(UserDefaults.standard.double(forKey: "taskArcLineWidth")),
            isAnalogArcStyle: UserDefaults.standard.bool(forKey: "isAnalogArcStyle"),
            showTimeOnlyForActiveTask: UserDefaults.standard.bool(forKey: "showTimeOnlyForActiveTask"),
            fontName: UserDefaults.standard.string(forKey: "fontName") ?? "SF Pro",
            digitalFont: UserDefaults.standard.string(forKey: "digitalFont") ?? "SF Pro",
            digitalFontSize: UserDefaults.standard.double(forKey: "digitalFontSize"),
            lightModeDigitalFontColor: UserDefaults.standard.string(forKey: "lightModeDigitalFontColor") ?? Color.black.toHex(),
            darkModeDigitalFontColor: UserDefaults.standard.string(forKey: "darkModeDigitalFontColor") ?? Color.white.toHex(),
            lightModeHandColor: lightModeHandColor,
            darkModeHandColor: darkModeHandColor
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
            
            // Применяем настройки циферблата - без передачи markersViewModel,
            // так как в этом контексте у нас его может не быть
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
