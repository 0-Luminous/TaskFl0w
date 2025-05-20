// //
// //  EnhancedEditWatchFaceView.swift
// //  TaskFl0w
// //
// //  Created by Yan on 7/5/25.
// //

// import SwiftUI

// // Улучшенный экран редактирования циферблата
// struct EnhancedEditWatchFaceView: View {
//     @Environment(\.dismiss) private var dismiss
//     @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    
//     let watchFace: WatchFaceModel
//     @State private var editedName: String
//     @State private var showingDeleteAlert = false
    
//     init(watchFace: WatchFaceModel) {
//         self.watchFace = watchFace
//         _editedName = State(initialValue: watchFace.name)
//     }
    
//     // Добавляем функцию для генерации виброотдачи
//     private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
//         let generator = UIImpactFeedbackGenerator(style: style)
//         generator.prepare()
//         generator.impactOccurred()
//     }
    
//     // Модификатор для текстового поля
//     private struct TextFieldModifier: ViewModifier {
//         func body(content: Content) -> some View {
//             content
//                 .padding()
//                 .background(Color(red: 0.18, green: 0.18, blue: 0.18))
//                 .cornerRadius(10)
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 10)
//                         .stroke(
//                             LinearGradient(
//                                 colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)],
//                                 startPoint: .topLeading,
//                                 endPoint: .bottomTrailing
//                             ),
//                             lineWidth: 1
//                         )
//                 )
//                 .foregroundColor(.white)
//                 .padding(.horizontal)
//         }
//     }
    
//     var body: some View {
//         NavigationStack {
//             ZStack {
//                 Color(red: 0.098, green: 0.098, blue: 0.098)
//                     .ignoresSafeArea()
                
//                 VStack(spacing: 24) {
//                     TextField("Название циферблата", text: $editedName)
//                         .modifier(TextFieldModifier())
                    
//                     // Предпросмотр циферблата
//                     Text("Предпросмотр")
//                         .font(.headline)
//                         .foregroundColor(.yellow)
//                         .frame(maxWidth: .infinity, alignment: .leading)
//                         .padding(.horizontal)
                    
//                     EnhancedWatchFacePreviewCard(watchFace: watchFace, isSelected: true)
//                         .scaleEffect(1.2)
//                         .padding(.bottom, 20)
                    
//                     Spacer()
                    
//                     // Кнопка удаления
//                     Button {
//                         generateHapticFeedback(style: .rigid)
//                         showingDeleteAlert = true
//                     } label: {
//                         HStack {
//                             Image(systemName: "trash")
//                             Text("Удалить циферблат")
//                         }
//                         .padding()
//                         .frame(maxWidth: .infinity)
//                         .background(
//                             LinearGradient(
//                                 colors: [.red, .red.opacity(0.8)],
//                                 startPoint: .topLeading,
//                                 endPoint: .bottomTrailing
//                             )
//                         )
//                         .foregroundColor(.white)
//                         .cornerRadius(10)
//                         .padding(.horizontal)
//                     }
                    
//                     // Кнопка сохранения
//                     Button {
//                         if !editedName.isEmpty {
//                             generateHapticFeedback()
//                             var updatedFace = watchFace
//                             updatedFace.name = editedName
//                             libraryManager.updateWatchFace(updatedFace)
//                             dismiss()
//                         }
//                     } label: {
//                         Text("Сохранить")
//                             .fontWeight(.semibold)
//                             .padding()
//                             .frame(maxWidth: .infinity)
//                             .background(
//                                 !editedName.isEmpty
//                                     ? LinearGradient(
//                                         colors: [.blue, .blue.opacity(0.8)],
//                                         startPoint: .topLeading,
//                                         endPoint: .bottomTrailing
//                                       )
//                                     : LinearGradient(
//                                         colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
//                                         startPoint: .topLeading,
//                                         endPoint: .bottomTrailing
//                                       )
//                             )
//                             .foregroundColor(.white)
//                             .cornerRadius(10)
//                             .padding(.horizontal)
//                     }
//                     .disabled(editedName.isEmpty)
//                 }
//                 .padding(.vertical)
//             }
//             .navigationTitle("Редактирование")
//             .navigationBarTitleDisplayMode(.inline)
//             .toolbar {
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     Button(action: {
//                         generateHapticFeedback()
//                         dismiss()
//                     }) {
//                         HStack {
//                             Image(systemName: "chevron.left")
//                             Text("Отмена")
//                         }
//                         .foregroundColor(.white)
//                     }
//                 }
//             }
//             .alert("Удалить циферблат?", isPresented: $showingDeleteAlert) {
//                 Button("Отмена", role: .cancel) { 
//                     generateHapticFeedback()
//                 }
//                 Button("Удалить", role: .destructive) {
//                     generateHapticFeedback(style: .rigid)
//                     libraryManager.deleteWatchFace(watchFace.id)
//                     dismiss()
//                 }
//             } message: {
//                 Text("Действие нельзя отменить")
//             }
//         }
//     }
// } 