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
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? 
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(
                                    gradient: Gradient(colors: [Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2.5 : 0
                        )
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.5) : Color.clear, radius: 3)
            
            Text(category.rawValue)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
