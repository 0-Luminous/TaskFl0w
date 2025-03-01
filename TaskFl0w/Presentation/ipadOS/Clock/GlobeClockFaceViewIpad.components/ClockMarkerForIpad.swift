//
//  MainClockMarker.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockMarkerForIpad: View {
    let hour: Int
    let style: MarkerStyle
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("showHourNumbers") private var showHourNumbers = true
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor = Color.gray.toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor = Color.gray.toHex()
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    @AppStorage("numbersSize") private var numbersSize: Double = 16.0
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Отображать только числа, как на скриншоте
                if showHourNumbers {
                    Text("\(hour)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.black)
                        .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0) - zeroPosition))
                }
                
                // Маленькие черточки для каждого часа
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 1.5, height: 8)
                    .offset(y: -6)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - geometry.size.height * 0.4 + markersOffset)
        }
    }
    
    private var currentMarkersColor: Color {
        let hexColor = colorScheme == .dark ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }
}
