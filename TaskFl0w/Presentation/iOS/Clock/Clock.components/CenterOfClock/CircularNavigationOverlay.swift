//
//  CircularNavigationOverlay.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//

import SwiftUI

struct CircularNavigationOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    var onPreviousDay: () -> Void
    var onNextDay: () -> Void
    //    @Binding var isDraggingOver: ClockViewModel.NavigationButton?

    var body: some View {
        ZStack {
            // Внешний круг-подложка с серой окантовкой
            Circle()
                .stroke(Color(red: 0.655, green: 0.639, blue: 0.639), lineWidth: 2)
                .frame(width: 170, height: 170)

            // Внутренний круг
            Circle()
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.192, green: 0.192, blue: 0.192)
                        : Color(red: 0.933, green: 0.933, blue: 0.933)
                )
                .frame(width: 170, height: 170)

            // Кнопки навигации
            HStack(spacing: 60) {
                // Левая кнопка (предыдущий день)
                Button(action: onPreviousDay) {
                    Image(systemName: "calendar.badge.minus")
                        .foregroundColor(.white)
                        .font(.system(size: 27))
                        .frame(width: 44, height: 44)
                }

                // Правая кнопка (следующий день)
                Button(action: onNextDay) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.white)
                        .font(.system(size: 27))
                        .frame(width: 44, height: 44)
                }
            }
        }
    }
}
