import SwiftUI

struct ClockControlsView: View {
   @ObservedObject var viewModel: ClockViewModel
   @ObservedObject var markersViewModel: ClockMarkersViewModel
   @ObservedObject private var themeManager = ThemeManager.shared
   
   @Binding var showFontPicker: Bool
   @Binding var showSizeSettings: Bool
   @Binding var showIntervalSettings: Bool
   @Binding var fontName: String
   
   // Удаляем состояние для настройки цвета стрелки - переносим в ColorControlsView
   // @State private var showHandColorSettings: Bool = false
   // @AppStorage переменные оставляем, так как они нужны для сохранения данных
   @AppStorage("lightModeHandColor") private var lightModeHandColor: String = "#007AFF"
   @AppStorage("darkModeHandColor") private var darkModeHandColor: String = "#007AFF"
   
   var body: some View {
       VStack(spacing: 16) {
           Text("Настройки циферблата")
               .font(.headline)
               .foregroundColor(themeManager.isDarkMode ? .white : .black)

           if showFontPicker {
               HStack {
                   Text("Выберите шрифт")
                       .font(.headline)
                       .foregroundColor(themeManager.isDarkMode ? .white : .black)
                       
                   Spacer()

                   Button(action: {
                       withAnimation {
                           showFontPicker = false
                       }
                   }) {
                       Text("Готово")
                           .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           .fontWeight(.medium)
                   }
               }
               .padding(.bottom, 8)

               Picker(
                   "",
                   selection: Binding(
                       get: { markersViewModel.fontName },
                       set: {
                           markersViewModel.fontName = $0
                           fontName = $0
                           // Добавляем обновление digitalFont
                           if viewModel.themeConfig.clockStyle == "Цифровой" {
                               viewModel.themeConfig.digitalFont = $0
                               UserDefaults.standard.set($0, forKey: "digitalFont")
                           }
                       }
                   )
               ) {
                   ForEach(markersViewModel.customFonts, id: \.self) { font in
                       Text(font).tag(font)
                   }
               }
               .pickerStyle(.wheel)
               .foregroundColor(themeManager.isDarkMode ? .white : .black)
           } else if showSizeSettings {
               // Настройки размера цифр
               HStack {
                   Text(viewModel.themeConfig.clockStyle == "Цифровой" ? "Размер цифр на часах" : "Размер цифр")
                       .font(.headline)
                       .foregroundColor(themeManager.isDarkMode ? .white : .black)

                   Spacer()

                   Button(action: {
                       withAnimation {
                           showSizeSettings = false
                       }
                   }) {
                       Text("Готово")
                           .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           .fontWeight(.medium)
                   }
               }
               .padding(.bottom, 8)
               
               if viewModel.themeConfig.clockStyle == "Цифровой" {
                   // Настройки размера для цифрового стиля
                   HStack(spacing: 10) {
                       Button(action: {
                           if markersViewModel.digitalFontSize > 30 {
                               markersViewModel.digitalFontSize -= 2
                               viewModel.themeConfig.digitalFontSize = markersViewModel.digitalFontSize
                           }
                       }) {
                           Text("Меньше")
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       Text("\(Int(markersViewModel.digitalFontSize))")
                           .font(.system(size: 23))
                           .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           .frame(width: 30)
                       
                       Button(action: {
                           if markersViewModel.digitalFontSize < 60 {
                               markersViewModel.digitalFontSize += 2
                               viewModel.themeConfig.digitalFontSize = markersViewModel.digitalFontSize
                           }
                       }) {
                           Text("Больше")
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
               } else {
                   // Существующие настройки размера для других стилей
                   HStack(spacing: 10) {
                       Button(action: {
                           if markersViewModel.numbersSize > 14 {
                               markersViewModel.numbersSize -= 1
                               viewModel.themeConfig.numbersSize = markersViewModel.numbersSize
                           }
                       }) {
                           Text("Меньше")
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       Text("\(Int(markersViewModel.numbersSize))")
                           .font(.system(size: 23))
                           .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           .frame(width: 30)
                       
                       Button(action: {
                           if markersViewModel.numbersSize < 21 {
                               markersViewModel.numbersSize += 1
                               viewModel.themeConfig.numbersSize = markersViewModel.numbersSize
                           }
                       }) {
                           Text("Больше")
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
               }
           } else if showIntervalSettings {
               // Настройки интервала цифр
               HStack {
                   Text("Интервал цифр")
                       .font(.headline)
                       .foregroundColor(themeManager.isDarkMode ? .white : .black)

                   Spacer()

                   Button(action: {
                       withAnimation {
                           showIntervalSettings = false
                       }
                   }) {
                       Text("Готово")
                           .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           .fontWeight(.medium)
                   }
               }
               .padding(.bottom, 8)
               
               HStack(spacing: 10) {
                   Button(action: {
                       viewModel.themeConfig.numberInterval = 2
                       markersViewModel.numberInterval = 2
                   }) {
                       Text("2 часа")
                   }
                   .buttonStyle(isSelected: viewModel.themeConfig.numberInterval == 2)
                   
                   Button(action: {
                       viewModel.themeConfig.numberInterval = 3
                       markersViewModel.numberInterval = 3
                   }) {
                       Text("3 часа")
                   }
                   .buttonStyle(isSelected: viewModel.themeConfig.numberInterval == 3)
                   
                   Button(action: {
                       viewModel.themeConfig.numberInterval = 6
                       markersViewModel.numberInterval = 6
                   }) {
                       Text("6 часов")
                   }
                   .buttonStyle(isSelected: viewModel.themeConfig.numberInterval == 6)
               }
           } else {
               // Показываем настройки цифр только для стиля "Минимализм"
               if viewModel.themeConfig.clockStyle == "Минимализм" {
                   // Первая строка: показать/скрыть и интервал
                   HStack(spacing: 10) {
                       // Кнопка показать/скрыть цифры
                       Button(action: {
                           markersViewModel.showHourNumbers.toggle()
                           viewModel.themeConfig.showHourNumbers = markersViewModel.showHourNumbers
                       }) {
                           HStack {
                               Text(markersViewModel.showHourNumbers ? "Скрыть" : "Показать")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Image(systemName: markersViewModel.showHourNumbers ? "eye.slash" : "eye")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       // Для стиля "Минимализм" сохраняем настройки интервала
                       Button(action: {
                           withAnimation {
                               showIntervalSettings = true
                           }
                       }) {
                           HStack {
                               Text("Интервал")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Text("\(viewModel.themeConfig.numberInterval) ч")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                   .padding(.leading, 2)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
                   .padding(.bottom, 6)
                   
                   // Вторая строка: шрифт и размер для Минимализма
                   HStack(spacing: 10) {
                       // Кнопка изменения шрифта
                       Button(action: {
                           withAnimation {
                               showFontPicker = true
                           }
                       }) {
                           HStack {
                               Text("Шрифт")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Image(systemName: "textformat")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       // Кнопка размера цифр
                       Button(action: {
                           withAnimation {
                               showSizeSettings = true
                           }
                       }) {
                           HStack {
                               Text("Размер")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Text("\(Int(markersViewModel.numbersSize))")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                   .padding(.leading, 2)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
                   .padding(.bottom, 6)
               }

               // Кнопки шрифта и размера для классического стиля
               if viewModel.themeConfig.clockStyle == "Классический" {
                   HStack(spacing: 10) {
                       // Кнопка изменения шрифта
                       Button(action: {
                           withAnimation {
                               showFontPicker = true
                           }
                       }) {
                           HStack {
                               Text("Шрифт")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Image(systemName: "textformat")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       // Кнопка размера цифр
                       Button(action: {
                           withAnimation {
                               showSizeSettings = true
                           }
                       }) {
                           HStack {
                               Text("Размер")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Text("\(Int(markersViewModel.numbersSize))")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                   .padding(.leading, 2)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
                   .padding(.bottom, 6)
               }
               
               // Добавим блок для цифрового стиля
               if viewModel.themeConfig.clockStyle == "Цифровой" {
                   HStack(spacing: 10) {
                       // Кнопка изменения шрифта
                       Button(action: {
                           withAnimation {
                               showFontPicker = true
                           }
                       }) {
                           HStack {
                               Text("Шрифт")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Image(systemName: "textformat")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       // Кнопка размера цифр
                       Button(action: {
                           withAnimation {
                               showSizeSettings = true
                           }
                       }) {
                           HStack {
                               Text("Размер")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                               Text("\(Int(markersViewModel.digitalFontSize))")
                                   .font(.caption)
                                   .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                   .padding(.leading, 2)
                           }
                           .padding(.vertical, 6)
                           .padding(.horizontal, 10)
                           .frame(maxWidth: .infinity)
                           .background(
                               Capsule()
                                   .fill(themeManager.isDarkMode ? 
                                       Color(red: 0.184, green: 0.184, blue: 0.184) : 
                                       Color(red: 0.95, green: 0.95, blue: 0.95))
                                   .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                           )
                           .overlay(
                               Capsule()
                                   .stroke(
                                       LinearGradient(
                                           gradient: Gradient(colors: [
                                               Color.gray.opacity(0.7),
                                               Color.gray.opacity(0.3),
                                           ]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing
                                       ),
                                       lineWidth: 1.0
                                   )
                           )
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
                   .padding(.bottom, 6)
               }
               
               Text("Стиль")
                   .font(.subheadline)
                   .foregroundColor(themeManager.isDarkMode ? .white : .black)
                   .frame(maxWidth: .infinity, alignment: .leading)

               VStack(spacing: 10) {
                   HStack(spacing: 10) {
                       Button(action: {
                           viewModel.themeConfig.clockStyle = "Классический"
                           if viewModel.themeConfig.numberInterval > 1 {
                               viewModel.themeConfig.numberInterval = 1
                               markersViewModel.numberInterval = 1
                           }
                           // При выходе из "Минимализм" включаем отображение цифр
                           viewModel.themeConfig.showHourNumbers = true
                           markersViewModel.showHourNumbers = true
                       }) {
                           Text("Классический")
                               .buttonStyle(isSelected: viewModel.themeConfig.clockStyle == "Классический")
                       }
                       .buttonStyle(PlainButtonStyle())

                       Button(action: {
                           // Отключаем действие кнопки - оставляем пустой блок
                       }) {
                           Text("Контур")
                               .buttonStyle(isDisabled: true)
                       }
                       .buttonStyle(PlainButtonStyle())
                       .disabled(true) 
                       .overlay(
                           // Добавляем индикатор "скоро будет доступно"
                           Text("скоро")
                               .font(.system(size: 8, weight: .semibold))
                               .foregroundColor(.yellow.opacity(0.8))
                               .padding(.horizontal, 4)
                               .padding(.vertical, 1)
                               .background(Color.black.opacity(0.5))
                               .cornerRadius(4)
                               .offset(x: 0, y: -12), 
                           alignment: .top
                       )
                   }

                   HStack(spacing: 10) {
                       Button(action: {
                           viewModel.themeConfig.clockStyle = "Цифровой"
                           if viewModel.themeConfig.numberInterval > 1 {
                               viewModel.themeConfig.numberInterval = 1
                               markersViewModel.numberInterval = 1
                           }
                           // При переходе на "Цифровой" стиль отключаем отображение цифр
                           viewModel.themeConfig.showHourNumbers = false
                           markersViewModel.showHourNumbers = false
                       }) {
                           Text("Цифровой")
                               .buttonStyle(isSelected: viewModel.themeConfig.clockStyle == "Цифровой")
                       }
                       .buttonStyle(PlainButtonStyle())

                       Button(action: {
                           viewModel.themeConfig.clockStyle = "Минимализм"
                           // При переходе в "Минимализм" устанавливаем интервал 2 часа
                           viewModel.themeConfig.numberInterval = 2
                           markersViewModel.numberInterval = 2
                           // При переходе в "Минимализм" включаем отображение цифр
                           viewModel.themeConfig.showHourNumbers = true
                           markersViewModel.showHourNumbers = true
                       }) {
                           Text("Минимализм")
                               .buttonStyle(isSelected: viewModel.themeConfig.clockStyle == "Минимализм")
                       }
                       .buttonStyle(PlainButtonStyle())
                   }
               }
               .padding(.bottom, 8)
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
   
   // Оставляем это свойство, так как оно может использоваться в других местах
   private var currentHandColor: Color {
       let hexColor = themeManager.isDarkMode ? darkModeHandColor : lightModeHandColor
       return Color(hex: hexColor) ?? .blue
   }
} 
