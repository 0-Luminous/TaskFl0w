import SwiftUI

struct MarkersControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @Binding var showMarkers: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Маркеры")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Первая строка с переключателем отображения маркеров
            HStack(spacing: 10) {
                Button(action: {
                    markersViewModel.showMarkers.toggle()
                    showMarkers = markersViewModel.showMarkers
                }) {
                    HStack {
                        Text(markersViewModel.showMarkers ? "Скрыть маркеры" : "Показать маркеры")
                            .font(.caption)
                            .foregroundColor(.white)
                        Image(systemName: markersViewModel.showMarkers ? "eye.slash" : "eye")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(
                        color: markersViewModel.showMarkers ? Color.yellow.opacity(0.2) : Color.black.opacity(0.5),
                        radius: markersViewModel.showMarkers ? 5 : 3,
                        x: 0,
                        y: markersViewModel.showMarkers ? 0 : 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой")
                .opacity(!markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой" ? 0.5 : 1)
            }
            .padding(.bottom, 8)
            
            // Вторая строка с управлением толщиной
            if markersViewModel.showMarkers {
                HStack(spacing: 10) {
                    // Кнопка уменьшения толщины
                    Button(action: {
                        if markersViewModel.markersWidth > 1.0 {
                            markersViewModel.markersWidth -= 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Тоньше")
                                .font(.caption)
                                .foregroundColor(.white)
                            Image(systemName: "minus")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth <= 1.0)
                    .opacity(markersViewModel.markersWidth <= 1.0 ? 0.5 : 1)
                    
                    // Значение толщины
                    Text("\(markersViewModel.markersWidth, specifier: "%.1f")")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .frame(width: 40)
                    
                    // Кнопка увеличения толщины
                    Button(action: {
                        if markersViewModel.markersWidth < 8.0 {
                            markersViewModel.markersWidth += 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Толще")
                                .font(.caption)
                                .foregroundColor(.white)
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth >= 8.0)
                    .opacity(markersViewModel.markersWidth >= 8.0 ? 0.5 : 1)
                }
                .padding(.bottom, 8)
                
                // Дополнительная информация о маркерах
                Text("Толщина маркеров влияет на визуальное отображение циферблата. Более тонкие маркеры создают минималистичный вид, а более толстые обеспечивают лучшую видимость.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
} 