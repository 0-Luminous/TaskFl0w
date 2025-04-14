//
//  CategoryGridContent.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI
// Новая структура для содержимого сетки
  struct CategoryGridContent<Content: View>: View {
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
           .background(backgroundColorForTheme)
           .cornerRadius(20)
           .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
       }
   }
