import SwiftUI

struct PersonalizationViewIOS: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    
    var body: some View {
        ZStack {
            // Карточки
            VStack(spacing: 20) { // Добавили spacing между кнопками
                Spacer()
                    .frame(height: 50) // Отступ сверху
                
                // Основной цвет
                Button {
                    // Действие для основного цвета
                } label: {
                    CardView(
                        icon: "square.filled.on.square",
                        title: "Основной\nцвет"
                    )
                }
                .buttonStyle(CardButtonStyle())
                
                // Циферблат
                Button {
                    showingClockFaceEditor = true
                } label: {
                    CardView(
                        icon: "clock.circle",
                        title: "Циферблат"
                    )
                }
                .buttonStyle(CardButtonStyle())
                
                // Категории
                Button {
                    showingCategoryEditor = true
                } label: {
                    CardView(
                        icon: "folder.fill.badge.gearshape",
                        title: "Категории"
                    )
                }
                .buttonStyle(CardButtonStyle())
                
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



