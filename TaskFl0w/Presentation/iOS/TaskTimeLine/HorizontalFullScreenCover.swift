//
//  HorizontalFullScreenCover.swift
//  TaskFl0w
//
//  Created by Yan on 3/5/25.
//

import SwiftUI

// Добавляем кастомный модификатор для fullScreenCover с анимацией справа налево
struct HorizontalFullScreenCover<ContentView: View>: ViewModifier {
    @Binding var isPresented: Bool
    let contentBuilder: () -> ContentView
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Показываем полноэкранное покрытие только когда isPresented == true
            if isPresented {
                // Полупрозрачный фон
                // Color.black.opacity(0.4)
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                    // .transition(.opacity)
                
                // Содержимое, которое выезжает справа налево
                GeometryReader { geo in
                    NavigationStack {
                        contentBuilder()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .transition(.move(edge: .trailing)) // Справа налево
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented) // Более быстрая анимация
    }
}

// Расширение для View, чтобы добавить наш кастомный модификатор
extension View {
    func horizontalFullScreenCover<ContentView: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ContentView
    ) -> some View {
        self.modifier(HorizontalFullScreenCover(isPresented: isPresented, contentBuilder: content))
    }
}
