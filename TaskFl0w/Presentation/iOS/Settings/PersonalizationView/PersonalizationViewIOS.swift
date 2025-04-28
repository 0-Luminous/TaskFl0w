import SwiftUI

struct PersonalizationViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    @State private var showingClockEditor = false
    
    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.098, blue: 0.098) // Задний фон
                .ignoresSafeArea() // Чтобы цвет был на весь экран

            VStack(spacing: 20) { // Добавили spacing между кнопками
                Spacer()
                    .frame(height: 50) // Отступ сверху
                
                // Основной цвет
                Button {
                    showingClockEditor = true
                } label: {
                    CardView(
                        icon: "square.filled.on.square",
                        title: "Базовый цвет"
                    )
                }
                
                // Циферблат
                Button {
                    showingClockFaceEditor = true
                } label: {
                    CardView(
                        icon: "clock.circle",
                        title: "Циферблат"
                    )
                }
                
                // Категории
                Button {
                    showingCategoryEditor = true
                } label: {
                    CardView(
                        icon: "folder.fill.badge.gearshape",
                        title: "Категории"
                    )
                }
                
                Spacer()
                
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                    Text("Назад")
                }
            }
        }
        .fullScreenCover(isPresented: $showingClockEditor) {
            ClockEditorView(taskArcLineWidth: viewModel.taskArcLineWidth)
        }
        .fullScreenCover(isPresented: $showingClockFaceEditor) {
            ClockFaceEditorViewIOS()
        }
        .fullScreenCover(isPresented: $showingCategoryEditor) {
            CategoryEditorViewIOS(
                viewModel: viewModel,
                isPresented: $showingCategoryEditor
            )
        }
    }
}
#Preview {
    NavigationView {
        PersonalizationViewIOS()
    }
}



