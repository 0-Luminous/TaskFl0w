//
//  MainClockMarker.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct MainClockMarker: View {
    let hour: Int
    let style: MarkerStyle
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("showHourNumbers") private var showHourNumbers = true
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor = Color.gray.toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor = Color.gray.toHex()
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    
    var body: some View {
        VStack(spacing: 0) {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(currentMarkersColor)
                    .frame(width: markersWidth, height: 12)
                if showHourNumbers {
                    Text("\(hour)")
                        .font(.system(size: 12))
                        .foregroundColor(currentMarkersColor)
                        .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0)))
                        .offset(y: 5)
                }
                
            case .lines:
                Rectangle()
                    .fill(currentMarkersColor)
                    .frame(width: markersWidth, height: hour % 6 == 0 ? 16 : 12)
                
            case .dots:
                Circle()
                    .fill(currentMarkersColor)
                    .frame(width: hour % 6 == 0 ? 6 : 4, height: hour % 6 == 0 ? 6 : 4)
            }
        }
        .offset(y: -(UIScreen.main.bounds.width * 0.35 - markersOffset))
    }
    
    private var currentMarkersColor: Color {
        let hexColor = colorScheme == .dark ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }
}
