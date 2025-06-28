func setDeadlineForSelectedTasks(_ deadline: Date) {
    logger.info("🎯 Устанавливаем deadline для \(self.state.selectedTasks.count) задач: \(deadline)")
    
    let selectedTaskIds = Array(self.state.selectedTasks) // Копируем чтобы не потерять после clearSelection
    
    Task {
        var successCount = 0
        var errorCount = 0
        
        // Обновляем каждую задачу последовательно
        for taskId in selectedTaskIds {
            logger.info("📝 Устанавливаем deadline для задачи: \(taskId)")
            
            guard let task = self.state.items.first(where: { $0.id == taskId }) else {
                logger.warning("❌ Задача с ID \(taskId) не найдена для установки deadline")
                errorCount += 1
                continue
            }
            
            let updatedTask = ToDoItem(
                id: task.id,
                title: task.title,
                date: task.date,
                isCompleted: task.isCompleted,
                categoryID: task.categoryID,
                categoryName: task.categoryName,
                priority: task.priority,
                deadline: deadline
            )
            
            do {
                logger.info("💾 Сохраняем задачу \(taskId) с deadline: \(deadline)")
                try await todoDataService.updateTask(updatedTask)
                
                await MainActor.run {
                    // Обновляем локальное состояние сразу
                    if let index = self.state.items.firstIndex(where: { $0.id == taskId }) {
                        self.state.items[index] = updatedTask
                        logger.info("✅ Локально обновлена задача \(taskId)")
                    }
                    
                    // 🔧 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Обновляем filteredItems тоже
                    if let index = self.state.filteredItems.firstIndex(where: { $0.id == taskId }) {
                        self.state.filteredItems[index] = updatedTask
                        logger.info("✅ Локально обновлена отфильтрованная задача \(taskId)")
                    }
                }
                
                successCount += 1
                logger.info("✅ Успешно установлен deadline для задачи: \(taskId)")
            } catch {
                errorCount += 1
                logger.error("❌ Ошибка установки deadline для задачи \(taskId): \(error)")
            }
        }
        
        // После завершения всех операций обновляем UI
        await MainActor.run {
            logger.info("🎉 Завершено: успешно \(successCount), ошибок \(errorCount)")
            
            // 🔧 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Принудительно перезагружаем данные из базы
            Task {
                do {
                    let freshTasks = try await self.todoDataService.loadTasks(for: self.state.selectedDate)
                    await MainActor.run {
                        self.state.items = freshTasks
                        self.applyCurrentFilters()
                        
                        // 🔧 ВАЖНО: Очищаем selection только ПОСЛЕ полного обновления данных
                        if successCount > 0 {
                            // Задержка для обеспечения полного обновления UI
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.state.selectedTasks.removeAll()
                                self.state.isSelectionMode = false
                                self.logger.info("✅ Selection очищен после полного обновления данных")
                            }
                        }
                        
                        self.logger.info("✅ Завершена установка deadline для всех выбранных задач")
                    }
                } catch {
                    self.logger.error("❌ Ошибка перезагрузки данных после установки deadline: \(error)")
                }
            }
        }
    }
} 