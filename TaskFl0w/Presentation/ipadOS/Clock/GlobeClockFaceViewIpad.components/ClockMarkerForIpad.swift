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
    @AppStorage("numbersSize") private var numbersSize: Double = 14.0
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(currentMarkersColor)
                    .frame(width: markersWidth, height: 10)
                if showHourNumbers {
                    Text("\(hour)")
                        .font(.system(size: numbersSize))
                        .foregroundColor(currentMarkersColor)
                        .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0) - zeroPosition))
                        .offset(y: 4)
                }
                
            case .lines:
                Rectangle()
                    .fill(currentMarkersColor)
                    .frame(width: markersWidth, height: hour % 6 == 0 ? 14 : 10)
                
            case .dots:
                Circle()
                    .fill(currentMarkersColor)
                    .frame(width: hour % 6 == 0 ? 5 : 3, height: hour % 6 == 0 ? 5 : 3)
            }
        }
        .offset(y: -(UIScreen.main.bounds.width * 0.18 - markersOffset))
    }
    
    private var currentMarkersColor: Color {
        let hexColor = colorScheme == .dark ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }
}
