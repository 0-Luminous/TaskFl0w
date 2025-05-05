import SwiftUI

struct PersonalizationViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    @State private var showingClockEditor = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.098, blue: 0.098)  // Задний фон
                .ignoresSafeArea()  // Чтобы цвет был на весь экран

            VStack(spacing: 20) {  // Добавили spacing между кнопками
                Spacer()
                    .frame(height: 50)  // Отступ сверху

                // Основной цвет
                Button {
                    showingClockEditor = true
                } label: {
                    CardView(
                        icon: "bell.badge.fill",
                        title: "Уведомления"
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
            NavigationView {
                SoundAndNotification()
            }
        }
        .fullScreenCover(isPresented: $showingClockFaceEditor) {
            ClockEditorView(
                viewModel: viewModel,
                markersViewModel: viewModel.markersViewModel,
                taskArcLineWidth: viewModel.taskArcLineWidth
            )
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
        PersonalizationViewIOS(viewModel: ClockViewModel())
    }
}
