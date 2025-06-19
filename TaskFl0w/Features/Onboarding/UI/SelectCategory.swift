//
//  SelectCategory.swift
//  TaskFl0w
//
//  Created by Yan on 13/5/25.
//

import SwiftUI

struct SelectCategory: View {
    @StateObject private var viewModel = SelectCategoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var navigateToMainApp = false
    @AppStorage("isFirstViewCompleted") private var isFirstViewCompleted: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 30) {
                        introText
                        categoriesGrid
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .background(backgroundColor)

            // Кнопка внизу для продолжения
            VStack {
                Spacer()

                Button(action: {
                    withAnimation {
                        viewModel.saveSelectedCategories {
                            // После сохранения категорий активируем переход
                            navigateToMainApp = true
                        }
                    }
                }) {
                    Text("navigation.continue".localized())
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    viewModel.selectedCategories.isEmpty
                                        ? AnyShapeStyle(.ultraThinMaterial)
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.Blue1,
                                                    Color.Purple1,
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                        .foregroundColor(
                            viewModel.selectedCategories.isEmpty
                                ? (themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                                : .black
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .disabled(viewModel.selectedCategories.isEmpty)
                .opacity(viewModel.selectedCategories.isEmpty ? 0.7 : 1)
                .padding(.bottom, 20)
            }
        }
        .overlay(loadingOverlay)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $navigateToMainApp) {
            // Полноэкранный переход на основной экран приложения
            ClockViewIOS()
        }
    }

    // MARK: - UI Components

    private var introText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("selectCategory.description.start".localized())
                .font(.title2.bold())
                .foregroundColor(themeManager.isDarkMode ? .white : .black)

            Text("selectCategory.description.choose".localized())
                .font(.subheadline)
                .foregroundColor(
                    themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var categoriesGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.startCategories, id: \.id) { category in
                CategoryCard(
                    category: category,
                    isSelected: viewModel.selectedCategories.contains { $0.id == category.id },
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleCategory(category)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("selectCategory.description.loading".localized())
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.2).opacity(0.8))
                    )
                }
                .transition(.opacity)
            }
        }
    }

    private var backgroundColor: Color {
        themeManager.isDarkMode
            ? Color(red: 0.08, green: 0.08, blue: 0.08) : Color(red: 0.97, green: 0.97, blue: 0.97)
    }
}

// MARK: - Category Card View
struct CategoryCard: View {
    let category: TaskCategoryModel
    let isSelected: Bool
    let onTap: () -> Void
    let hapticsManager = HapticsManager.shared

    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: {
            onTap()
            hapticsManager.triggerSelectionFeedback()
        }) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: category.color.opacity(0.5), radius: isSelected ? 10 : 4, x: 0,
                            y: 2
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .scaleEffect(isPressed ? 0.95 : 1.0)

                    Image(systemName: category.iconName)
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                }

                VStack(spacing: 5) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)

                    Text(getDescription(for: category.rawValue))
                        .font(.caption)
                        .foregroundColor(
                            themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.6)
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? Color(white: 0.15) : .white)
                    .shadow(
                        color: themeManager.isDarkMode ? .black.opacity(0.3) : .gray.opacity(0.3),
                        radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressAction(
            onPress: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
            },
            onRelease: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            })
    }

    private func getDescription(for category: String) -> String {
        switch category {
        case "selectCategory.work".localized():
            return "selectCategory.title.work".localized()
        case "selectCategory.education".localized():
            return "selectCategory.title.education".localized()
        case "selectCategory.break".localized():
            return "selectCategory.title.break".localized()
        case "selectCategory.rest".localized():
            return "selectCategory.title.rest".localized()
        case "selectCategory.hobby".localized():
            return "selectCategory.title.hobby".localized()
        case "selectCategory.sport".localized():
            return "selectCategory.title.sport".localized()
        case "selectCategory.food".localized():
            return "selectCategory.title.food".localized()
        case "selectCategory.sleep".localized():
            return "selectCategory.title.sleep".localized()
        case "selectCategory.travel".localized():
            return "selectCategory.title.travel".localized()
        case "selectCategory.meditation".localized():
            return "selectCategory.title.meditation".localized()
        default:
            return "Персональная категория"
        }
    }
}

// MARK: - View Model
final class SelectCategoryViewModel: ObservableObject {
    @Published var startCategories: [TaskCategoryModel] = []
    @Published var selectedCategories: [TaskCategoryModel] = []
    @Published var isLoading: Bool = false

    let categoryManagement: CategoryManagementProtocol

    @MainActor
    init(
        categoryManagement: CategoryManagementProtocol? = nil
    ) {
        if let categoryManagement = categoryManagement {
            self.categoryManagement = categoryManagement
        } else {
            // Создаем с базовой инициализацией для Preview
            let context = PersistenceController.shared.container.viewContext
            let sharedState = SharedStateService()
            self.categoryManagement = CategoryManagement(context: context, sharedState: sharedState)
        }
        setupDefaultCategories()
    }

    func setupDefaultCategories() {
        // Создаем набор стандартных категорий
        startCategories = [
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.work".localized(), iconName: "briefcase",
                color: .Blue1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.education".localized(), iconName: "book",
                color: .Purple1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.break".localized(),
                iconName: "cup.and.saucer", color: .Mint1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.rest".localized(), iconName: "beach.umbrella",
                color: .Teal1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.hobby".localized(), iconName: "paintpalette",
                color: .Orange1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.sport".localized(), iconName: "figure.run",
                color: .red1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.food".localized(), iconName: "fork.knife",
                color: .green1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.sleep".localized(), iconName: "moon.stars",
                color: .Indigo1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.travel".localized(), iconName: "airplane",
                color: .BlueJay1),
            TaskCategoryModel(
                id: UUID(), rawValue: "selectCategory.meditation".localized(), iconName: "sparkles",
                color: .Pink1),
        ]
    }

    func toggleCategory(_ category: TaskCategoryModel) {
        if selectedCategories.contains(where: { $0.id == category.id }) {
            selectedCategories.removeAll { $0.id == category.id }
        } else {
            selectedCategories.append(category)
        }
    }

    func selectAllCategories() {
        selectedCategories = startCategories
    }

    func saveSelectedCategories(completion: @escaping () -> Void = {}) {
        isLoading = true

        // Имитируем задержку для анимации загрузки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            for category in self.selectedCategories {
                self.categoryManagement.addCategory(category)
            }

            // После завершения
            DispatchQueue.main.async {
                self.isLoading = false

                // Устанавливаем флаг в UserDefaults, что настройка завершена
                UserDefaults.standard.set(true, forKey: "isAppSetupCompleted")

                // Вызываем замыкание для перехода к основному экрану
                completion()
            }
        }
    }
}

// MARK: - Gesture Extensions
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    SelectCategory()
}
