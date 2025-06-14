//
//  ColorSchemeManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Combine

// MARK: - Color Scheme Types
enum ColorSchemeType: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .light: return "Светлая"
        case .dark: return "Темная"
        case .auto: return "Системная"
        }
    }
}

// MARK: - Theme Colors
struct ThemeColors {
    let clockFace: Color
    let outerRing: Color
    let markers: Color
    let hands: Color
    let digitalFont: Color
    let taskArcs: Color
    
    static let lightDefault = ThemeColors(
        clockFace: .white,
        outerRing: .gray.opacity(0.3),
        markers: .black,
        hands: .blue,
        digitalFont: .gray,
        taskArcs: .blue
    )
    
    static let darkDefault = ThemeColors(
        clockFace: .black,
        outerRing: .gray.opacity(0.3),
        markers: .white,
        hands: .blue,
        digitalFont: .white,
        taskArcs: .blue
    )
}

// MARK: - Color Scheme Manager
@MainActor
final class ColorSchemeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentScheme: ColorSchemeType = .auto {
        didSet {
            saveScheme()
            updateCurrentColors()
        }
    }
    
    @Published private(set) var currentColors: ThemeColors = .lightDefault
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadScheme()
        setupSystemThemeObserver()
        updateCurrentColors()
    }
    
    // MARK: - Public Properties
    var isDarkMode: Bool {
        switch currentScheme {
        case .light: return false
        case .dark: return true
        case .auto: return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    // MARK: - Private Methods
    private func loadScheme() {
        let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") ?? ColorSchemeType.auto.rawValue
        currentScheme = ColorSchemeType(rawValue: savedScheme) ?? .auto
    }
    
    private func saveScheme() {
        UserDefaults.standard.set(currentScheme.rawValue, forKey: "colorScheme")
    }
    
    private func setupSystemThemeObserver() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleSystemThemeChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleSystemThemeChange() {
        guard currentScheme == .auto else { return }
        updateCurrentColors()
    }
    
    private func updateCurrentColors() {
        currentColors = isDarkMode ? .darkDefault : .lightDefault
    }
    
    // MARK: - Public Methods
    func setScheme(_ scheme: ColorSchemeType) {
        currentScheme = scheme
    }
    
    func toggleScheme() {
        switch currentScheme {
        case .light: currentScheme = .dark
        case .dark: currentScheme = .auto
        case .auto: currentScheme = .light
        }
    }
    
    func resetToDefaults() {
        currentScheme = .auto
    }
    
    // MARK: - Color Access Methods
    func clockFaceColor() -> Color {
        return currentColors.clockFace
    }
    
    func outerRingColor() -> Color {
        return currentColors.outerRing
    }
    
    func markersColor() -> Color {
        return currentColors.markers
    }
    
    func handsColor() -> Color {
        return currentColors.hands
    }
    
    func digitalFontColor() -> Color {
        return currentColors.digitalFont
    }
    
    func taskArcsColor() -> Color {
        return currentColors.taskArcs
    }
} 