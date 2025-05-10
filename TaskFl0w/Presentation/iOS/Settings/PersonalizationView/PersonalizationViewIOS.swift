import SwiftUI

struct PersonalizationViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClockViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    @State private var showingClockEditor = false
    @State private var showingWatchFaceLibrary = false

    var body: some View {
        ZStack {
            (themeManager.isDarkMode ? 
                Color(red: 0.098, green: 0.098, blue: 0.098) :
                Color(red: 0.95, green: 0.95, blue: 0.95))
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
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(themeManager.isDarkMode ? 
                                        Color(red: 0.184, green: 0.184, blue: 0.184) :
                                        Color(red: 0.9, green: 0.9, blue: 0.9))
                            )
                            .frame(width: 40, height: 40)
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
                            .frame(width: 40, height: 40)
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.3) : 
                                .black.opacity(0.1), 
                                radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Уведомления")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.isDarkMode ? .primary : .black)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(themeManager.isDarkMode ? 
                                Color(red: 0.2, green: 0.2, blue: 0.2) :
                                Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.2) : 
                                .black.opacity(0.1), 
                                radius: 3, y: 1)
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
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(themeManager.isDarkMode ? 
                                        Color(red: 0.184, green: 0.184, blue: 0.184) :
                                        Color(red: 0.9, green: 0.9, blue: 0.9))
                            )
                            .frame(width: 40, height: 40)
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
                            .frame(width: 40, height: 40)
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.3) : 
                                .black.opacity(0.1), 
                                radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Библиотека циферблатов")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.isDarkMode ? .primary : .black)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(themeManager.isDarkMode ? 
                                Color(red: 0.2, green: 0.2, blue: 0.2) :
                                Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.2) : 
                                .black.opacity(0.1), 
                                radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // Циферблат
                Button {
                    showingClockFaceEditor = true
                } label: {
                    HStack {
                        Image(systemName: "clock.circle")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(themeManager.isDarkMode ? 
                                        Color(red: 0.184, green: 0.184, blue: 0.184) :
                                        Color(red: 0.9, green: 0.9, blue: 0.9))
                            )
                            .frame(width: 40, height: 40)
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
                            .frame(width: 40, height: 40)
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.3) : 
                                .black.opacity(0.1), 
                                radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Циферблат")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.isDarkMode ? .primary : .black)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(themeManager.isDarkMode ? 
                                Color(red: 0.2, green: 0.2, blue: 0.2) :
                                Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.2) : 
                                .black.opacity(0.1), 
                                radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                // Категории
                Button {
                    showingCategoryEditor = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill.badge.gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(themeManager.isDarkMode ? 
                                        Color(red: 0.184, green: 0.184, blue: 0.184) :
                                        Color(red: 0.9, green: 0.9, blue: 0.9))
                            )
                            .frame(width: 40, height: 40)
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
                            .frame(width: 40, height: 40)
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.3) : 
                                .black.opacity(0.1), 
                                radius: 3, x: 0, y: 1)
                            .padding(.leading, 16)

                        Text("Категории")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.isDarkMode ? .primary : .black)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(themeManager.isDarkMode ? 
                                Color(red: 0.2, green: 0.2, blue: 0.2) :
                                Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: themeManager.isDarkMode ? 
                                .black.opacity(0.2) : 
                                .black.opacity(0.1), 
                                radius: 3, y: 1)
                    )
                    .padding(.horizontal, 16)
                }

                Spacer()

                // Переключатель темы
                ThemeModeToggle()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)


            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.red1)
                    Text("Назад")
                        .foregroundColor(.red1)
                }
            }
        }
        .foregroundColor(themeManager.isDarkMode ? .white : .black)
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
