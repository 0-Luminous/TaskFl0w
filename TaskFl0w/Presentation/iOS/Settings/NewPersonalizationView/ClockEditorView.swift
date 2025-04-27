//
//  ClockEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 27/4/25.
//

import SwiftUI

struct ClockEditorView: View {
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    let taskArcLineWidth: CGFloat

    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.gray.toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray.toHex()

    @Environment(\.presentationMode) var presentationMode
    @State private var showClockControls = false
    @State private var showColorControls = false
    @State private var showOuterRingWidthControls = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    clockPreviewSection
                        .padding(.bottom, (showClockControls || showColorControls || showOuterRingWidthControls) ? 180 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                }

                VStack(spacing: 0) {
                    if showClockControls {
                        clockControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showColorControls {
                        colorControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showOuterRingWidthControls {
                        outerRingWidthControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    dockBar
                }
                .animation(.spring(), value: showClockControls)
                .animation(.spring(), value: showColorControls)
            }
        }
    }

    private var clockPreviewSection: some View {
        ZStack {
            // Внешнее кольцо
            Circle()
                .stroke(currentOuterRingColor, lineWidth: viewModel.outerRingLineWidth)
                .frame(
                    width: UIScreen.main.bounds.width * 0.8,
                    height: UIScreen.main.bounds.width * 0.8
                )

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
    }

    private var currentOuterRingColor: Color {
        let isDarkMode = themeManager.isDarkMode
        let hexColor = isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }

    private var dockBar: some View {
        HStack(spacing: 40) {
            Button(action: {
                // Открыть clockControls, закрыть colorControls
                withAnimation {
                    showClockControls.toggle()
                    if showClockControls { showColorControls = false }
                }
            }) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(showClockControls ? .yellow : .white)
            }

            Button(action: {
                // Открыть colorControls, закрыть clockControls
                withAnimation {
                    showColorControls.toggle()
                    if showColorControls { showClockControls = false }
                }
            }) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 24))
                    .foregroundColor(showColorControls ? .yellow : .white)
            }

            Button(action: {
                withAnimation {
                    showOuterRingWidthControls.toggle()
                    if showOuterRingWidthControls {
                        showClockControls = false
                        showColorControls = false
                    }
                }
            }) {
                Image(systemName: "clock.circle" )
                    .font(.system(size: 24))
                    .foregroundColor(showOuterRingWidthControls ? .yellow : .white)
            }
            
            Button(action: {
                // Действие 4
            }) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            Button(action: {
                // Действие 5
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                .shadow(radius: 8)
        )
        .padding(.bottom, 24)
    }

    private var clockControls: some View {
        VStack(spacing: 16) {
            Text("Настройки циферблата")
                .font(.headline)
                .foregroundColor(.white)
            Toggle("Показывать цифры", isOn: $markersViewModel.showHourNumbers)
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .foregroundColor(.white)
            // Stepper("Интервал цифр: \(markersViewModel.numberInterval)", value: $markersViewModel.numberInterval, in: 1...6)
            //     .foregroundColor(.white)
            Stepper("Толщина маркеров: \(markersViewModel.markersWidth, specifier: "%.1f")", value: $markersViewModel.markersWidth, in: 1...8, step: 0.5)
                .foregroundColor(.white)
            Stepper("Размер цифр: \(markersViewModel.numbersSize, specifier: "%.0f")", value: $markersViewModel.numbersSize, in: 10...32, step: 1)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private var colorControls: some View {
        VStack(spacing: 16) {
            Text("Цвета циферблата")
                .font(.headline)
                .foregroundColor(.white)
            // Внешнее кольцо
            ColorPicker("Внешнее кольцо", selection: Binding(
                get: {
                    Color(hex: themeManager.isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor) ?? .gray.opacity(0.3)
                },
                set: { newColor in
                    if themeManager.isDarkMode {
                        darkModeOuterRingColor = newColor.toHex()
                    } else {
                        lightModeOuterRingColor = newColor.toHex()
                    }
                }
            ))
            .foregroundColor(.white)
            // Цвет циферблата
            ColorPicker("Циферблат", selection: Binding(
                get: {
                    Color(hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor) ?? (themeManager.isDarkMode ? .black : .white)
                },
                set: { newColor in
                    if themeManager.isDarkMode {
                        darkModeClockFaceColor = newColor.toHex()
                    } else {
                        lightModeClockFaceColor = newColor.toHex()
                    }
                }
            ))
            .foregroundColor(.white)
            // Цвет маркеров
            ColorPicker("Маркеры", selection: Binding(
                get: {
                    Color(hex: themeManager.isDarkMode ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
                },
                set: { newColor in
                    if themeManager.isDarkMode {
                        darkModeMarkersColor = newColor.toHex()
                    } else {
                        lightModeMarkersColor = newColor.toHex()
                    }
                }
            ))
            .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private var outerRingWidthControls: some View {
        VStack(spacing: 16) {
            Text("Толщина внешнего кольца: \(Int(viewModel.outerRingLineWidth)) pt")
                .font(.headline)
                .foregroundColor(.white)
            Slider(
                value: Binding(
                    get: { viewModel.outerRingLineWidth },
                    set: { viewModel.outerRingLineWidth = $0 }
                ),
                in: 20...60,
                step: 1
            )
            
            Divider().background(Color.white.opacity(0.2))
            
            Text("Толщина дуги задачи: \(Int(viewModel.taskArcLineWidth)) pt")
                .font(.headline)
                .foregroundColor(.white)
            Slider(value: $viewModel.taskArcLineWidth, in: 20...32, step: 1)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
}
