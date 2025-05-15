//
//  CategoryGridContent.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI
// Новая структура для содержимого сетки
  struct CategoryGridContent<Content: View>: View {
       @ObservedObject private var themeManager = ThemeManager.shared
       @Binding var currentPage: Int
       let numberOfPages: Int
       let backgroundColorForTheme: Color
       let shadowColorForTheme: Color
       let content: (Int) -> Content

       var body: some View {
           VStack {
               TabView(selection: $currentPage) {
                   ForEach(0..<numberOfPages, id: \.self) { page in
                       content(page)
                   }
               }
               .frame(height: 100)
               .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
           }
           .background(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
           .cornerRadius(24)
           .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
       }
   }
