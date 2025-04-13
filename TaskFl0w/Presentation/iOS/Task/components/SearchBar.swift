//
//  SearchBar.swift
//  ToDoList
//
//  Created by Yan on 23/3/25.
//
import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 6)
            TextField("Search", text: $text)
                .padding(.vertical, 7)
                .font(.system(size: 17))
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 10)
    }
}
