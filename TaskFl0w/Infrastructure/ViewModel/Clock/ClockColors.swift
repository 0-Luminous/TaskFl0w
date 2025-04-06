//
//  ClockColors.swift
//  TaskFl0w
//
//  Created by Yan on 5/4/25.
//
import SwiftUI

struct ClockColors {
    // MARK: - AppStorage Properties

    @AppStorage("lightModeOuterRingColor") static var lightModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") static var darkModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("zeroPosition") static var zeroPosition: Double = 0.0

    // AppStorage для маркеров
    @AppStorage("showHourNumbers") static var showHourNumbers: Bool = true
    @AppStorage("markersWidth") static var markersWidth: Double = 2.0
    @AppStorage("markersOffset") static var markersOffset: Double = 40.0
    @AppStorage("numbersSize") static var numbersSize: Double = 12.0
    @AppStorage("lightModeMarkersColor") static var lightModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("darkModeMarkersColor") static var darkModeMarkersColor: String = Color.gray
        .toHex()

    // MARK: - Computed Properties

    static func currentOuterRingColor(colorScheme: ColorScheme) -> Color {
        let hexColor = colorScheme == .dark ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
}
