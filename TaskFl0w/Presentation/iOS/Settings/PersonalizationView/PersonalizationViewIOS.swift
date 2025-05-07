import SwiftUI

struct PersonalizationViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    @State private var showingClockEditor = false
    @State private var showingWatchFaceLibrary = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.098, blue: 0.098)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer()
                    .frame(height: 50)

                // Уведомления
                Button {
                    showingClockEditor = true
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Уведомления")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // Библиотека циферблатов (новая кнопка)
                Button {
                    showingWatchFaceLibrary = true
                } label: {
                    HStack {
                        Image(systemName: "tray.full.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Библиотека циферблатов")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // Циферблат
                Button {
                    showingClockFaceEditor = true
                } label: {
                    HStack {
                        Image(systemName: "clock.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Циферблат")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // Категории
                Button {
                    showingCategoryEditor = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill.badge.gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Категории")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
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
        .fullScreenCover(isPresented: $showingWatchFaceLibrary) {
            LibraryOfWatchFaces()
        }
    }
}

#Preview {
    NavigationView {
        PersonalizationViewIOS(viewModel: ClockViewModel())
    }
}
