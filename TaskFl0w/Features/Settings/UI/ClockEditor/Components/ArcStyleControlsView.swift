import SwiftUI

struct ArcStyleControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var showTimeOnlyForActiveTask: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Стиль отображения")
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Первая строка: Аналоговый вид дуги
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation {
                        viewModel.themeConfig.isAnalogArcStyle = false
                    }
                }) {
                    Text("Стандартный")
                        .buttonStyle(isSelected: !viewModel.themeConfig.isAnalogArcStyle)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation {
                        viewModel.themeConfig.isAnalogArcStyle = true
                    }
                }) {
                    Text("Аналоговый")
                        .buttonStyle(isSelected: viewModel.themeConfig.isAnalogArcStyle)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            if !viewModel.themeConfig.isAnalogArcStyle {
                Text("Отображение времени")
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Вторая строка: Отображение времени
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation {
                            viewModel.themeConfig.showTimeOnlyForActiveTask = false
                            showTimeOnlyForActiveTask = false
                        }
                    }) {
                        HStack {
                            Text("Всегда")
                                .font(.caption)
                                .foregroundColor(!viewModel.themeConfig.showTimeOnlyForActiveTask ? 
                                    (themeManager.isDarkMode ? .yellow : .red1) : 
                                    (themeManager.isDarkMode ? .white : .black))
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle(isSelected: !viewModel.themeConfig.showTimeOnlyForActiveTask)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation {
                            viewModel.themeConfig.showTimeOnlyForActiveTask = true
                            showTimeOnlyForActiveTask = true
                        }
                    }) {
                        HStack {
                            Text("Активная задача")
                                .font(.caption)
                                .foregroundColor(viewModel.themeConfig.showTimeOnlyForActiveTask ? 
                                    (themeManager.isDarkMode ? .yellow : .red1) : 
                                    (themeManager.isDarkMode ? .white : .black))
                            Image(systemName: "clock.badge")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle(isSelected: viewModel.themeConfig.showTimeOnlyForActiveTask)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 8)
            }
            
            // Дополнительная информация
            Text("Аналоговый стиль дуги гармонирует с внешним кольцом. Выбор времени влияет на отображение времени начала и конца задач.")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
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