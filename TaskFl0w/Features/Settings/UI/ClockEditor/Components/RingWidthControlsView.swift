import SwiftUI

struct RingWidthControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Толщина кольца")
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Управление толщиной внешнего кольца
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Внешнее кольцо")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.outerRingLineWidth)) pt")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                }
                
                HStack(spacing: 10) {
                    // Кнопка уменьшения толщины
                    Button(action: {
                        if viewModel.outerRingLineWidth > 20 {
                            viewModel.outerRingLineWidth -= 1
                        }
                    }) {
                        HStack {
                            Text("Тоньше")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            Image(systemName: "minus")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.outerRingLineWidth <= 20)
                    .opacity(viewModel.outerRingLineWidth <= 20 ? 0.5 : 1)
                    
                    // Слайдер для более точной настройки
                    Slider(
                        value: Binding(
                            get: { viewModel.outerRingLineWidth },
                            set: { viewModel.outerRingLineWidth = $0 }
                        ),
                        in: 20...38,
                        step: 1
                    )
                    .frame(maxWidth: .infinity)
                    .accentColor(themeManager.isDarkMode ? .yellow : .red1)
                    
                    // Кнопка увеличения толщины
                    Button(action: {
                        if viewModel.outerRingLineWidth < 38 {
                            viewModel.outerRingLineWidth += 1
                        }
                    }) {
                        HStack {
                            Text("Толще")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.outerRingLineWidth >= 38)
                    .opacity(viewModel.outerRingLineWidth >= 38 ? 0.5 : 1)
                }
            }
            .padding(.bottom, 8)
            
            // Секция для толщины дуги задачи
            if !viewModel.isAnalogArcStyle {
                Divider()
                    .background(themeManager.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Дуга задачи")
                            .font(.subheadline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.taskArcLineWidth)) pt")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                    }
                    
                    HStack(spacing: 10) {
                        // Кнопка уменьшения толщины дуги
                        Button(action: {
                            if viewModel.taskArcLineWidth > 20 {
                                viewModel.taskArcLineWidth -= 1
                            }
                        }) {
                            HStack {
                                Text("Тоньше")
                                    .font(.caption)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                Image(systemName: "minus")
                                    .font(.caption)
                                    .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                            }
                            .buttonStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.taskArcLineWidth <= 20)
                        .opacity(viewModel.taskArcLineWidth <= 20 ? 0.5 : 1)
                        
                        // Слайдер для дуги
                        Slider(
                            value: $viewModel.taskArcLineWidth,
                            in: 20...26,
                            step: 1
                        )
                        .frame(maxWidth: .infinity)
                        .accentColor(themeManager.isDarkMode ? .yellow : .red1)
                        
                        // Кнопка увеличения толщины дуги
                        Button(action: {
                            if viewModel.taskArcLineWidth < 26 {
                                viewModel.taskArcLineWidth += 1
                            }
                        }) {
                            HStack {
                                Text("Толще")
                                    .font(.caption)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                Image(systemName: "plus")
                                    .font(.caption)
                                    .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                            }
                            .buttonStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.taskArcLineWidth >= 26)
                        .opacity(viewModel.taskArcLineWidth >= 26 ? 0.5 : 1)
                    }
                }
                
                // Дополнительная информация
                Text("Толщина кольца и дуги влияет на визуальное восприятие циферблата. При аналоговом стиле толщина дуги совпадает с толщиной кольца.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else {
                // Информация при аналоговом стиле
                Text("В аналоговом стиле толщина дуги задачи соответствует толщине внешнего кольца для более гармоничного вида.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.isDarkMode ? 
                    Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98) :
                    Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
} 