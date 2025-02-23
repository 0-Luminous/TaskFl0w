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
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer() // Отодвигает текст вниз
                
                Text(title)
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? .coral : .black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20) // Отступ снизу
            }
            
            // Иконка в правом верхнем углу
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding([.top, .trailing], 20)
        }
        .frame(width: 160, height: 160)
        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 15, x: 0, y: 8)
    }
}

extension Color {
    static let coral = Color(red: 1.0, green: 0.5, blue: 0.31)
}
