//
//  MyProfileView.swift
//  TaskFl0w
//
//  Created by Yan on 24/2/25.
//

import SwiftUI

struct MyProfileView: View {
    @State private var userName: String = "Иван Иванов"
    @State private var userEmail: String = "ivan@example.com"
    @State private var userStatus: String = "Доступен"
    @State private var showingEditProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Фото профиля
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                // Информация пользователя
                VStack(spacing: 8) {
                    Text(userName)
                        .font(.title)
                        .bold()
                    
                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(userStatus)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(20)
                }
                
                // Кнопка редактирования
                Button(action: {
                    showingEditProfile = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Редактировать профиль")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Мой профиль")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userName: $userName,
                          userEmail: $userEmail,
                          userStatus: $userStatus)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var userStatus: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Личная информация")) {
                    TextField("Имя", text: $userName)
                    TextField("Email", text: $userEmail)
                    TextField("Статус", text: $userStatus)
                }
            }
            .navigationTitle("Редактировать профиль")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyProfileView()
        }
    }
}

