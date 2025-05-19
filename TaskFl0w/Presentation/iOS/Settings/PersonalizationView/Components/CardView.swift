//
//  CardView.swift
//  TaskFl0w
//
//  Created by Yan on 24/2/25.
//
import SwiftUI

struct CardView: View {
    let icon: String
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Иконка по центру сверху
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

            Spacer()

            // Текст по центру снизу
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
        }
        .frame(width: 160, height: 160)
        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(24)
        // .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 15, x: 0, y: 8)
    }
}
