//
//  CategoryButton.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CategoryButton: View {
    let category: TaskCategoryModel
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(category.color)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                )
            
            Text(category.rawValue)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
