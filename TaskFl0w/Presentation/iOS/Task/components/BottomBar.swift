//
// BottomBar.swift
// ToDoList
//
// Created by Yan on 21/3/25.

import SwiftUI

struct BottomBar: View {
    let itemCount: Int
    let onAddTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Text("\(itemCount) задач")
                    .foregroundColor(.gray)
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                Spacer()
                Button(action: onAddTap) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(22)
                }
                Spacer()
                Text("Архив")
                    .foregroundColor(.gray)
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                Spacer()
            }
//             .padding(.horizontal, 16)
        }
    }
}

#Preview {
    BottomBar(itemCount: 5) {
        print("Add tapped")
    }
}
