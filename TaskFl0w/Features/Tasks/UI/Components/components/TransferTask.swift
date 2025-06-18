//
//  TransferTask.swift
//  TaskFl0w
//
//  Created by Yan on 12/6/25.
//
import SwiftUI

struct TransferTaskView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let selectedTasksCount: Int
    let onMoveTasksToDate: (Date) -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingContent = false

    // Функция для генерации виброотдачи
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(
                        colors: themeManager.isDarkMode
                            ? [
                                Color(red: 0.05, green: 0.05, blue: 0.08),
                                Color(red: 0.08, green: 0.08, blue: 0.12),
                            ]
                            : [
                                Color(red: 0.96, green: 0.97, blue: 0.98),
                                Color(red: 0.94, green: 0.95, blue: 0.97),
                            ]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Красивый заголовок с иконкой
                    VStack(spacing: 16) {
                        // Иконка переноса
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.8), Color.purple.opacity(0.6),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 8) {
                            Text("Перенос задач")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.isDarkMode ? .white : .primary)

                            Text("Выберите новую дату для \(selectedTasksCount) задач(и)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    themeManager.isDarkMode
                                        ? Color.white.opacity(0.7) : Color.secondary
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)

                    MonthCalendarView(
                        selectedDate: $selectedDate,
                        onHideCalendar: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        },
                        isSwipeToHideEnabled: false
                    )

                    Spacer(minLength: 30)

                    // Стильные кнопки
                    HStack(spacing: 16) {
                        // Кнопка отмены
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Отмена")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        themeManager.isDarkMode
                                            ? Color(red: 0.15, green: 0.15, blue: 0.18)
                                            : Color(red: 0.95, green: 0.95, blue: 0.97)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                themeManager.isDarkMode
                                                    ? Color.white.opacity(0.1)
                                                    : Color.gray.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Кнопка переноса
                        Button {
                            generateHapticFeedback(style: .medium)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onMoveTasksToDate(selectedDate)
                                isPresented = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Перенести")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedTasksCount == 0
                                            ? LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.gray.opacity(0.5),
                                                    Color.gray.opacity(0.3),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue, Color.purple,
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                                    .shadow(
                                        color: selectedTasksCount == 0
                                            ? Color.clear : Color.blue.opacity(0.4),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                        }
                        .disabled(selectedTasksCount == 0)
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(selectedTasksCount == 0 ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .opacity(showingContent ? 1 : 0)
            .scaleEffect(showingContent ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    showingContent = true
                }
            }
        }
        .presentationDetents([.large])
    }
}

// Кастомный стиль кнопок с анимацией нажатия
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TransferTaskView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        selectedTasksCount: 3,
        onMoveTasksToDate: { _ in }
    )
}
