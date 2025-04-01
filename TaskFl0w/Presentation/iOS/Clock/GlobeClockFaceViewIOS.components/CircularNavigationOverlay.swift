//
//  CircularNavigationOverlay.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//

import SwiftUI

struct CircularNavigationOverlay: View {
    var onPreviousDay: () -> Void
    var onNextDay: () -> Void
    //    @Binding var isDraggingOver: ClockViewModel.NavigationButton?

    var body: some View {
        ZStack {
            // Основной круг-подложка с серой окантовкой
            Circle()
                .stroke(Color(red: 0.655, green: 0.639, blue: 0.639), lineWidth: 2)
                .frame(width: 170, height: 170)

            // Внутренний темный круг
            Circle()
                .fill(Color(red: 0.192, green: 0.192, blue: 0.192))   // #313131
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
