// //
// //  ZeroPositionControlView.swift
// //  TaskFl0w
// //
// //  Created by Yan on 13/5/25.
// //

// import SwiftUI

// struct ZeroPositionControlView: View {
//     @ObservedObject var viewModel: ClockViewModel
//     @ObservedObject private var themeManager = ThemeManager.shared
//     @State private var tempZeroPosition: Double
    
//     // Инициализатор для синхронизации начального значения
//     init(viewModel: ClockViewModel) {
//         self.viewModel = viewModel
//         // Инициализируем временное состояние текущим значением
//         _tempZeroPosition = State(initialValue: viewModel.timeManager.zeroPosition)
//     }
    
//     var body: some View {
//         VStack(spacing: 16) {
//             Text("Позиция нуля на циферблате")
//                 .font(.headline)
//                 .foregroundColor(themeManager.isDarkMode ? .white : .black)
//                 .frame(maxWidth: .infinity, alignment: .leading)
            
//             VStack(alignment: .leading, spacing: 10) {
//                 HStack {
//                     Text("Текущее положение: \(Int(tempZeroPosition))°")
//                         .font(.subheadline)
//                         .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
//                     Spacer()
                    
//                     Button(action: {
//                         tempZeroPosition = 0
//                         viewModel.updateZeroPosition(0)
//                         syncMarkersAndTasks()
//                     }) {
//                         Text("Сбросить")
//                             .font(.caption)
//                             .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
//                             .padding(.horizontal, 10)
//                             .padding(.vertical, 6)
//                             .background(
//                                 Capsule()
//                                     .fill(themeManager.isDarkMode ? 
//                                           Color(red: 0.184, green: 0.184, blue: 0.184) : 
//                                           Color(red: 0.95, green: 0.95, blue: 0.95))
//                                     .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
//                             )
//                     }
//                 }
                
//                 Slider(
//                     value: $tempZeroPosition,
//                     in: 0...345,
//                     step: 15
//                 )
//                 .accentColor(themeManager.isDarkMode ? .yellow : .red1)
//                 .onChange(of: tempZeroPosition) { _, newValue in
//                     viewModel.updateZeroPosition(newValue)
//                     syncMarkersAndTasks()
//                 }
                
//                 HStack {
//                     Text("0°")
//                         .font(.caption)
//                         .foregroundColor(.gray)
//                     Spacer()
//                     Text("345°")
//                         .font(.caption)
//                         .foregroundColor(.gray)
//                 }
                
//                 Text("Положение нуля определяет, в какой точке циферблата будет находиться 00:00. По умолчанию 00:00 находится сверху (0°).")
//                     .font(.caption)
//                     .foregroundColor(.gray)
//                     .frame(maxWidth: .infinity, alignment: .leading)
//                     .padding(.top, 8)
//             }
//         }
//         .padding()
//         .background(
//             RoundedRectangle(cornerRadius: 20)
//                 .fill(themeManager.isDarkMode ? 
//                       Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98) :
//                       Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.98))
//                 .shadow(radius: 8)
//         )
//         .padding(.horizontal, 24)
//         .onAppear {
//             // Синхронизируем состояние при появлении
//             tempZeroPosition = viewModel.timeManager.zeroPosition
//         }
//     }
    
//     // Функция для принудительного обновления маркеров и задач
//     private func syncMarkersAndTasks() {
//         // Форсируем обновление маркеров
//         viewModel.markersViewModel.zeroPosition = tempZeroPosition
//         viewModel.markersViewModel.updateCurrentThemeColors()
        
//         // Обновляем UI компонента
//         viewModel.objectWillChange.send()
//         viewModel.markersViewModel.objectWillChange.send()
        
//         // Обновляем через ZeroPositionManager для всех компонентов
//         ZeroPositionManager.shared.updateZeroPosition(tempZeroPosition)
//     }
// }

