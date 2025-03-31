//
//  BottomBar.swift
//  ToDoList
//
//  Created by Yan on 21/3/25.
//

// import SwiftUI

// struct BottomBar: View {
//     let itemCount: Int
//     let onAddTap: () -> Void

//     var body: some View {
//         ZStack {
//             Text("\(itemCount) Задач")
//                 .foregroundColor(.gray)
//                 .font(.system(size: 17))
//                 .frame(maxWidth: .infinity)

//             HStack {
//                 Spacer()
//                 Button(action: onAddTap) {
//                     Image(systemName: "square.and.pencil")
//                         .foregroundColor(.yellow)
//                         .font(.system(size: 22))
//                 }
//             }
//             .padding(.horizontal, 16)
//         }
//         .padding(.vertical, 12)
//         .background(Color(red: 0.153, green: 0.153, blue: 0.161))  // #272729
//         .overlay(
//             Rectangle()
//                 .frame(height: 0.5)
//                 .foregroundColor(Color(.systemGray6))
//                 .opacity(0.5),
//             alignment: .top
//         )
//     }
// }

// #Preview {
//     BottomBar(itemCount: 5) {
//         print("Add tapped")
//     }
// }
