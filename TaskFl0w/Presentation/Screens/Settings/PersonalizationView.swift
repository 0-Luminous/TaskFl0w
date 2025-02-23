import SwiftUI

struct PersonalizationView: View {
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
            ClockFaceEditorView()
        }
        .fullScreenCover(isPresented: $showingCategoryEditor) {
            CategoryEditorView(
                viewModel: viewModel,
                isPresented: $showingCategoryEditor
            )
        }
    }
}

struct CardView: View {
    let icon: String
    let title: String
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer() // Отодвигает текст вниз
                
                Text(title)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20) // Отступ снизу
            }
            
            // Иконка в правом верхнем углу
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.black)
                .padding([.top, .trailing], 20)
        }
        .frame(width: 160, height: 160)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.blue.opacity(configuration.isPressed ? 0.3 : 0), lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        PersonalizationView()
    }
}



