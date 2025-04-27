import SwiftUI

struct PersonalizationViewIOS: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    
    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.098, blue: 0.098) // Задний фон
                .ignoresSafeArea() // Чтобы цвет был на весь экран

            VStack(spacing: 20) { // Добавили spacing между кнопками
                Spacer()
                    .frame(height: 50) // Отступ сверху
                
                // Основной цвет
                Button {
                    // Действие для основного цвета
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
                
                // Заголовок внизу
                Text("Выберите редактор")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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



