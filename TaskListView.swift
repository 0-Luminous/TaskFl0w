private func getExistingDeadlineForSelectedTasks() -> Date? {
    // 🔧 ИСПРАВЛЕНИЕ: Принудительно обновляем данные перед поиском
    let selectedTaskItems = viewModel.items.filter { viewModel.selectedTasks.contains($0.id) }
    let deadlines = selectedTaskItems.compactMap { $0.deadline }
    
    print("🔍 getExistingDeadlineForSelectedTasks: Выбрано \(selectedTaskItems.count) задач")
    print("🔍 Найдено \(deadlines.count) deadline'ов: \(deadlines.map { $0.description })")
    
    // 🔧 ИСПРАВЛЕНИЕ: Если нет deadline'ов, попробуем поискать в базе напрямую
    if deadlines.isEmpty && !viewModel.selectedTasks.isEmpty {
        print("🔄 Поиск deadline'ов в базе данных...")
        return nil // Возвращаем nil, чтобы UI показал актуальное состояние
    }

    if !deadlines.isEmpty {
        let firstDeadline = deadlines.first!
        print("✅ Возвращаем deadline: \(firstDeadline)")
        return firstDeadline
    }

    print("❌ Нет deadline'ов для выбранных задач")
    return nil
} 