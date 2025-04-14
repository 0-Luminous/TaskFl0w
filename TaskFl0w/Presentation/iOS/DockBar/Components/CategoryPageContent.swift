//
//  CategoryPageContent.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI
// Новая структура для содержимого страницы
   struct CategoryPageContent: View {
       let categories: [TaskCategoryModel]
       let categoryWidth: CGFloat
       @Binding var selectedCategory: TaskCategoryModel?
       @Binding var draggedCategory: TaskCategoryModel?
       let moveCategory: (Int, Int) -> Void

       var body: some View {
           LazyVGrid(columns: [GridItem(.adaptive(minimum: categoryWidth))], spacing: 10) {
               ForEach(categories) { category in
                   CategoryButtonContent(
                       category: category,
                       categories: categories,
                       isSelected: selectedCategory == category,
                       categoryWidth: categoryWidth,
                       selectedCategory: $selectedCategory,
                       draggedCategory: $draggedCategory,
                       moveCategory: moveCategory
                   )
               }
           }
       }
   }
