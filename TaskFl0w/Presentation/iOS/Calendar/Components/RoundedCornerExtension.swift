// //
// //  RoundedCornerExtension.swift
// //  TaskFl0w
// //
// //  Created by Yan on 2/5/25.
// //

// import SwiftUI

// // Определения из UIKit для использования в SwiftUI
// enum UIRectCorner: Int {
//     case topLeft = 0
//     case topRight = 1
//     case bottomLeft = 2
//     case bottomRight = 3
//     case allCorners = 4
// }

// class UIBezierPath {
//     init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
//         // Реализация для SwiftUI
//     }
    
//     var cgPath: CGPath {
//         // Заглушка, возвращаем пустой путь
//         return CGPath(rect: .zero, transform: nil)
//     }
// }

// // Расширение для создания скругления только по определенным углам
// extension View {
//     func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//         clipShape(RoundedCorner(radius: radius, corners: corners))
//     }
// }

// struct RoundedCorner: Shape {
//     var radius: CGFloat = .infinity
//     var corners: UIRectCorner = .allCorners

//     func path(in rect: CGRect) -> Path {
//         let path = UIBezierPath(
//             roundedRect: rect,
//             byRoundingCorners: corners,
//             cornerRadii: CGSize(width: radius, height: radius)
//         )
//         return Path(path.cgPath)
//     }
// } 