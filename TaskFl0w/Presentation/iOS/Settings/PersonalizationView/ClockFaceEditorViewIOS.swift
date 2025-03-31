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
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white
        .toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black
        .toHex()
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    @AppStorage("numbersSize") private var numbersSize: Double = 12.0
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0  // 0 градусов = верх

    // Добавляем необходимые свойства для MainClockFaceView
    @StateObject private var viewModel = ClockViewModel()

    // Добавляем генератор обратной связи
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Предпросмотр циферблата
                ZStack {
                    // Внешнее кольцо
                    Circle()
                        .stroke(currentOuterRingColor, lineWidth: 20)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.8,
                            height: UIScreen.main.bounds.width * 0.8
                        )

                    // Сам циферблат
                    GlobleClockFaceViewIOS(
                        currentDate: viewModel.selectedDate,
                        tasks: viewModel.tasks,
                        viewModel: viewModel,
                        draggedCategory: .constant(nil),
                        clockFaceColor: currentClockFaceColor,
                        zeroPosition: zeroPosition
                    )
                }
                .frame(height: UIScreen.main.bounds.width * 0.8)
                .padding(.vertical, 20)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)

                // Настройки
                List {
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

                        Toggle("Тёмная тема", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { oldValue, newValue in
                                feedbackGenerator.impactOccurred()
                            }
                    }

                    Section(header: Text("ЦВЕТА")) {
                        ColorPicker(
                            "Цвет циферблата",
                            selection: Binding(
                                get: {
                                    Color(
                                        hex: isDarkMode
                                            ? darkModeClockFaceColor : lightModeClockFaceColor)
                                        ?? (isDarkMode ? .black : .white)
                                },
                                set: { newColor in
                                    if isDarkMode {
                                        darkModeClockFaceColor = newColor.toHex()
                                    } else {
                                        lightModeClockFaceColor = newColor.toHex()
                                    }
                                }
                            ))

                        ColorPicker(
                            "Цвет внешнего круга",
                            selection: Binding(
                                get: {
                                    Color(
                                        hex: isDarkMode
                                            ? darkModeOuterRingColor : lightModeOuterRingColor)
                                        ?? .gray.opacity(0.3)
                                },
                                set: { newColor in
                                    if isDarkMode {
                                        darkModeOuterRingColor = newColor.toHex()
                                    } else {
                                        lightModeOuterRingColor = newColor.toHex()
                                    }
                                }
                            ))

                        ColorPicker(
                            "Цвет маркеров",
                            selection: Binding(
                                get: {
                                    Color(
                                        hex: isDarkMode
                                            ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
                                },
                                set: { newColor in
                                    if isDarkMode {
                                        darkModeMarkersColor = newColor.toHex()
                                    } else {
                                        lightModeMarkersColor = newColor.toHex()
                                    }
                                }
                            ))
                    }

                    Section(header: Text("МАРКЕРЫ")) {
                        Toggle("Показывать цифры часов", isOn: $showHourNumbers)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Положение нуля")
                            Slider(value: $zeroPosition, in: 0...360, step: 30)
                                .onChange(of: zeroPosition) { oldValue, newValue in
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
                            Text("Текущее положение: \(Int(zeroPosition))°")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)

                        if showHourNumbers {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Размер цифр")
                                Slider(value: $numbersSize, in: 8...16, step: 1.0)
                                    .onChange(of: numbersSize) { oldValue, newValue in
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                HStack {
                                    Text("8")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("16")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Толщина маркеров")
                            Slider(value: $markersWidth, in: 1...4, step: 0.5)
                        }
                        .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Расположение маркеров")
                            Slider(value: $markersOffset, in: 20...60, step: 1.0)
                                .onChange(of: markersOffset) { oldValue, newValue in
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            HStack {
                                Text("Ближе к центру")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("Ближе к краю")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Редактор циферблата")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        feedbackGenerator.impactOccurred()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private var currentClockFaceColor: Color {
        let hexColor = isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        return Color(hex: hexColor) ?? (isDarkMode ? .black : .white)
    }

    private var currentOuterRingColor: Color {
        let hexColor = isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
}

#Preview {
    ClockFaceEditorViewIOS()
}
