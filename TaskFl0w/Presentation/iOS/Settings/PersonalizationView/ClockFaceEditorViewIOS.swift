//
//  ClockFaceEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 20/2/25.
//

import SwiftUI

struct ClockFaceEditorViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("isDarkMode") private var isDarkMode = false {
        didSet {
            // При изменении isDarkMode через AppStorage обновляем и ThemeManager
            themeManager.setTheme(isDarkMode)
        }
    }
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("numberInterval") private var numberInterval: Int = 1

    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Предпросмотр циферблата
                clockPreviewSection

                // Настройки
                settingsList
            }
            .padding(.top)
            .navigationTitle("Настройка циферблата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        // Гарантируем синхронизацию Theme и AppStorage перед закрытием
                        themeManager.setTheme(isDarkMode)
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(true)
            .onAppear {
                // Гарантируем, что isDarkMode синхронизирован с ThemeManager при появлении
                isDarkMode = themeManager.isDarkMode
                viewModel.isDarkMode = themeManager.isDarkMode
                markersViewModel.isDarkMode = themeManager.isDarkMode
            }
        }
        // Применяем цветовую схему для всего представления
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }

    // MARK: - UI Components

    private var clockPreviewSection: some View {
        ZStack {
            // Сам циферблат
            GlobleClockFaceViewIOS(
                currentDate: viewModel.selectedDate,
                tasks: viewModel.tasks,
                viewModel: viewModel,
                markersViewModel: markersViewModel,
                draggedCategory: .constant(nil),
                zeroPosition: viewModel.zeroPosition,
                taskArcLineWidth: viewModel.taskArcLineWidth,
                outerRingLineWidth: viewModel.outerRingLineWidth
            )
        }
        .frame(height: UIScreen.main.bounds.width * 0.8)
        .padding(.vertical, 20)
        // Используем текущую тему для предпросмотра, а не сохраненное значение
        .environment(\.colorScheme, themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            markersViewModel.showHourNumbers = showHourNumbers
            markersViewModel.numberInterval = numberInterval
        }
        .onChange(of: showHourNumbers) { _, newValue in
            markersViewModel.showHourNumbers = newValue
        }
        .onChange(of: themeManager.isDarkMode) { _, newValue in
            // Немедленно обновляем предпросмотр при изменении темы
            markersViewModel.isDarkMode = newValue
            viewModel.isDarkMode = newValue
            isDarkMode = newValue
        }
    }

    private var settingsList: some View {
        List {
            // Секция стиля циферблата
            clockStyleSection

            // Секция маркеров (оставляем только интервал отображения цифр)
            markersSection
        }
    }

    private var clockStyleSection: some View {
        Section(header: Text("СТИЛЬ ЦИФЕРБЛАТА")) {
            HStack {
                Text("Стиль")
                Spacer()
                Text(clockStyle.rawValue.capitalized)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                switch clockStyle {
                case .classic:
                    clockStyle = .minimal
                case .minimal:
                    clockStyle = .modern
                case .modern:
                    clockStyle = .classic
                }
            }

            Toggle("Тёмная тема", isOn: Binding(
                get: { themeManager.isDarkMode },
                set: { newValue in
                    // Используем themeManager напрямую для переключения темы
                    if newValue != themeManager.isDarkMode {
                        // Переключаем тему напрямую
                        themeManager.toggleDarkMode()
                        
                        // Синхронизируем локальное состояние
                        DispatchQueue.main.async {
                            // Обновляем isDarkMode для AppStorage
                            isDarkMode = themeManager.isDarkMode
                            
                            // Синхронизируем ViewModel
                            viewModel.isDarkMode = themeManager.isDarkMode
                            markersViewModel.isDarkMode = themeManager.isDarkMode
                            
                            // Применяем эффект вибрации
                            feedbackGenerator.impactOccurred()
                        }
                    }
                }
            ))
        }
    }

    private var markersSection: some View {
        Section(header: Text("МАРКЕРЫ")) {
            Toggle("Показывать цифры часов", isOn: $showHourNumbers)

            if showHourNumbers {
                hourNumberIntervalPicker
            }

            zeroPositionSlider
        }
    }

    private var hourNumberIntervalPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Интервал отображения цифр")
            
            Picker("Интервал", selection: $numberInterval) {
                Text("Все").tag(1)
                Text("2 часа").tag(2)
                Text("3 часа").tag(3)
                Text("6 часов").tag(6)
            }
            .pickerStyle(.segmented)
            .onChange(of: numberInterval) { oldValue, newValue in
                feedbackGenerator.impactOccurred()
                markersViewModel.numberInterval = newValue
            }
        }
        .padding(.vertical, 8)
    }

    private var zeroPositionSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Положение нуля")
            Slider(
                value: Binding(
                    get: { viewModel.zeroPosition },
                    set: { viewModel.updateZeroPosition($0) }
                ),
                in: 0...360,
                step: 15
            )
            .onChange(of: viewModel.zeroPosition) { oldValue, newValue in
                feedbackGenerator.impactOccurred()
            }
            HStack {
                Text("0°")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("360°")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("Текущее положение: \(Int(viewModel.zeroPosition))°")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ClockFaceEditorViewIOS()
}
