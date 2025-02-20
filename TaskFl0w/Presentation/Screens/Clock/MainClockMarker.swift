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
    
    @AppStorage("showHourNumbers") private var showHourNumbers = true
    @AppStorage("markersColor") private var markersColor = Color.gray.toHex()
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    
    var body: some View {
        VStack {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(Color(hex: markersColor) ?? .gray)
                    .frame(width: markersWidth, height: 15)
                if showHourNumbers {
                    Text("\(hour)")
                        .font(.caption)
                        .foregroundColor(Color(hex: markersColor) ?? .gray)
                        .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0)))
                }
                
            case .lines:
                Rectangle()
                    .fill(Color(hex: markersColor) ?? .gray)
                    .frame(width: markersWidth, height: hour % 6 == 0 ? 20 : 10)
                
            case .dots:
                Circle()
                    .fill(Color(hex: markersColor) ?? .gray)
                    .frame(width: hour % 6 == 0 ? 8 : 4, height: hour % 6 == 0 ? 8 : 4)
            }
        }
        .offset(y: -(UIScreen.main.bounds.width * 0.35 - 30))
    }
}
