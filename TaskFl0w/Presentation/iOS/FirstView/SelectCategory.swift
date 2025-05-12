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
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 30) {
                    introText
                    categoriesGrid
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            
            bottomButtons
        }
        .background(backgroundColor)
        .overlay(
            loadingOverlay
        )
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .padding()
            }
            
            Spacer()
            
            Text("Выберите стартовые категории")
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            // Пустая кнопка для баланса
            Button(action: {}) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.clear)
                    .padding()
            }
        }
        .background(
            themeManager.isDarkMode ? 
                Color(red: 0.12, green: 0.12, blue: 0.12) : 
                Color(red: 0.95, green: 0.95, blue: 0.95)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var introText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Давайте начнем вместе")
                .font(.title2.bold())
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Text("Выберите наиболее подходящие категории для ваших задач. Позже вы сможете добавить свои.")
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7))
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
    
    private var bottomButtons: some View {
        VStack {
            Button(action: {
                withAnimation {
                    viewModel.saveSelectedCategories()
                }
            }) {
                Text("Продолжить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedCategories.isEmpty ? Color.gray : Color.Blue1)
                    )
                    .padding(.horizontal)
            }
            .disabled(viewModel.selectedCategories.isEmpty)
            .opacity(viewModel.selectedCategories.isEmpty ? 0.7 : 1)
            
            Button(action: {
                withAnimation {
                    viewModel.selectAllCategories()
                }
            }) {
                Text("Выбрать все категории")
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                    .padding(.vertical, 10)
            }
        }
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(backgroundColor)
                .shadow(color: themeManager.isDarkMode ? .black : .gray.opacity(0.3), 
                        radius: 10, x: 0, y: -5)
        )
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
                        
                        Text("Настройка категорий...")
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
        themeManager.isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.08) : Color(red: 0.97, green: 0.97, blue: 0.97)
    }
}

// MARK: - Category Card View
struct CategoryCard: View {
    let category: TaskCategoryModel
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            onTap()
            generateHapticFeedback()
        }) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: category.color.opacity(0.5), radius: isSelected ? 10 : 4, x: 0, y: 2)
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
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.6))
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
                    .shadow(color: themeManager.isDarkMode ? .black.opacity(0.3) : .gray.opacity(0.3), 
                           radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressAction(onPress: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        }, onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = false
            }
        })
    }
    
    private func generateHapticFeedback() {
        #if os(iOS)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        #endif
    }
    
    private func getDescription(for category: String) -> String {
        switch category {
        case "Работа":
            return "Рабочие задачи и встречи"
        case "Учеба":
            return "Учебные активности и домашняя работа"
        case "Перерыв":
            return "Короткие перерывы для отдыха"
        case "Отдых":
            return "Полноценный отдых и релаксация"
        case "Хобби":
            return "Личное время для увлечений"
        case "Спорт":
            return "Тренировки и физическая активность"
        case "Еда":
            return "Приготовление и прием пищи"
        case "Сон":
            return "Время для сна и восстановления"
        case "Путешествия":
            return "Поездки и экскурсии"
        case "Медитация":
            return "Время для самосозерцания"
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
    
    init(categoryManagement: CategoryManagementProtocol = CategoryManagement(
        context: PersistenceController.shared.container.viewContext)) {
        self.categoryManagement = categoryManagement
        setupDefaultCategories()
    }
    
    func setupDefaultCategories() {
        // Создаем набор стандартных категорий
        startCategories = [
            TaskCategoryModel(id: UUID(), rawValue: "Работа", iconName: "briefcase", color: .Blue1),
            TaskCategoryModel(id: UUID(), rawValue: "Учеба", iconName: "book", color: .Purple1),
            TaskCategoryModel(id: UUID(), rawValue: "Перерыв", iconName: "cup.and.saucer", color: .Mint1),
            TaskCategoryModel(id: UUID(), rawValue: "Отдых", iconName: "beach.umbrella", color: .Teal1),
            TaskCategoryModel(id: UUID(), rawValue: "Хобби", iconName: "paintpalette", color: .Orange1),
            TaskCategoryModel(id: UUID(), rawValue: "Спорт", iconName: "figure.run", color: .red1),
            TaskCategoryModel(id: UUID(), rawValue: "Еда", iconName: "fork.knife", color: .green1),
            TaskCategoryModel(id: UUID(), rawValue: "Сон", iconName: "moon.stars", color: .Indigo1),
            TaskCategoryModel(id: UUID(), rawValue: "Путешествия", iconName: "airplane", color: .BlueJay1),
            TaskCategoryModel(id: UUID(), rawValue: "Медитация", iconName: "sparkles", color: .Pink1)
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
    
    func saveSelectedCategories() {
        isLoading = true
        
        // Имитируем задержку для анимации загрузки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            for category in self.selectedCategories {
                self.categoryManagement.addCategory(category)
            }
            
            // После завершения
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Переходим к основному экрану приложения
                NotificationCenter.default.post(name: NSNotification.Name("CategoriesSetupCompleted"), object: nil)
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

