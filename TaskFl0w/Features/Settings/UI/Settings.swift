import SwiftUI

struct PersonalizationViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClockViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingClockFaceEditor = false
    @State private var showingCategoryEditor = false
    @State private var showingClockEditor = false
    @State private var showingWatchFaceLibrary = false
    @State private var showingFirstView = false
    @State private var showingTaskSettings = false
    let hapticsManager = HapticsManager.shared

    // MARK: - Computed Properties
    private var backgroundColor: Color {
        themeManager.isDarkMode ? 
            Color(red: 0.098, green: 0.098, blue: 0.098) :
            Color(red: 0.95, green: 0.95, blue: 0.95)
    }
    
    private var buttonBackgroundColor: Color {
        themeManager.isDarkMode ? 
            Color(red: 0.2, green: 0.2, blue: 0.2) :
            Color(red: 0.95, green: 0.95, blue: 0.95)
    }
    
    private var iconBackgroundColor: Color {
        themeManager.isDarkMode ? 
            Color(red: 0.184, green: 0.184, blue: 0.184) :
            Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private var iconForegroundColor: Color {
        themeManager.isDarkMode ? .coral1 : .red1
    }
    
    private var textForegroundColor: Color {
        themeManager.isDarkMode ? .primary : .black
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? 
            .black.opacity(0.3) : 
            .black.opacity(0.1)
    }
    
    private var buttonShadowColor: Color {
        themeManager.isDarkMode ? 
            .black.opacity(0.2) : 
            .black.opacity(0.1)
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer()
                    .frame(height: 50)

                // Уведомления
                createSettingsButton(
                    icon: "bell.badge.fill",
                    title: "settings.notifications".localized,
                    action: {
                        hapticsManager.triggerSoftFeedback()
                        showingClockEditor = true
                    }
                )

                // Новая кнопка Задачи
                createSettingsButton(
                    icon: "checklist",
                    title: "settings.tasks".localized,
                    action: {
                        hapticsManager.triggerSoftFeedback()
                        showingTaskSettings = true
                    }
                )

                // Библиотека циферблатов (новая кнопка)
                createSettingsButton(
                    icon: "tray.full.fill",
                    title: "settings.watchFaceLibrary".localized,
                    action: {
                        hapticsManager.triggerSoftFeedback()
                        showingWatchFaceLibrary = true
                    }
                )

                // Циферблат
                createSettingsButton(
                    icon: "clock.fill",
                    title: "settings.clockFace".localized,
                    action: {
                        hapticsManager.triggerSoftFeedback()
                        showingClockFaceEditor = true
                    }
                )

                // Категории
                createSettingsButton(
                    icon: "folder.fill",
                    title: "settings.categories".localized,
                    action: {
                        hapticsManager.triggerSoftFeedback()
                        showingCategoryEditor = true
                    }
                )

                // Остальные кнопки...
            }
        }
        .navigationTitle("navigation.settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    hapticsManager.triggerSoftFeedback()
                    dismiss() 
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.red1)
                    Text("navigation.back".localized)
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
                taskArcLineWidth: viewModel.themeConfig.taskArcLineWidth
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
        .fullScreenCover(isPresented: $showingFirstView) {
            FirstView()
        }
        .fullScreenCover(isPresented: $showingTaskSettings) {
            SettingsTask()
        }
    }

    // MARK: - Private Methods
    private func createSettingsButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                createIconView(systemName: icon)
                
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(textForegroundColor)
                    .padding(.leading, 12)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 12)
            .background(createButtonBackground())
            .padding(.horizontal, 16)
        }
    }
    
    private func createIconView(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(iconForegroundColor)
            .padding(8)
            .background(
                Circle()
                    .fill(iconBackgroundColor)
            )
            .frame(width: 40, height: 40)
            .overlay(createIconOverlay())
            .frame(width: 40, height: 40)
            .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
            .padding(.leading, 16)
    }
    
    private func createIconOverlay() -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.7), 
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.0
            )
    }
    
    private func createButtonBackground() -> some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(buttonBackgroundColor)
            .shadow(color: buttonShadowColor, radius: 3, y: 1)
    }
}

#Preview {
    NavigationView {
        PersonalizationViewIOS(viewModel: ClockViewModel())
    }
}
