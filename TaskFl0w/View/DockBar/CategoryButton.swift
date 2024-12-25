import SwiftUI

struct CategoryButton: View {
    let category: TaskCategoryModel
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(category.color)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 3)
            )
            
            Text(category.rawValue)
                .font(.caption2)
                .foregroundColor(category.color)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(height: 80)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
