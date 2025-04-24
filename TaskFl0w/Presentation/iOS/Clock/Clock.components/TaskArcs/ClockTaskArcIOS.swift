import Foundation
//
//  ClockTaskArcIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockTaskArcIOS: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel

    // Добавляем состояние для отслеживания перетаскивания
    @State private var isDragging: Bool = false
    // Добавим состояние для контроля видимости
    @State private var isVisible: Bool = true

    var body: some View {
        if !isVisible {
            EmptyView()
        } else {
            GeometryReader { geometry in
                let center = CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                // Используем метод с учетом zeroPosition, чтобы задачи правильно отображались на циферблате
                // Важно: весь циферблат вращается в родительском компоненте, поэтому нам нужно
                // рассчитать углы без учета zeroPosition для правильного расположения дуг
                let (startAngle, endAngle) = RingTimeCalculator.calculateAngles(for: task)
                let midAngle = RingTimeCalculator.calculateMidAngle(
                    start: startAngle, end: endAngle)

                ZStack {
                    // Дуга задачи
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius + 10,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false)
                    }
                    .stroke(task.category.color, lineWidth: 20)
                    // Увеличиваем область contentShape для улучшения пользовательского опыта при перетаскивании
                    .contentShape(
                        // Определяем большую зону взаимодействия для всех жестов
                        Path { path in
                            // Создаем зону с точной угловой длиной дуги, но значительно увеличенной шириной
                            path.addArc(
                                center: center,
                                radius: radius + 30,  // Увеличиваем внешний радиус
                                startAngle: startAngle,  // Сохраняем оригинальные углы
                                endAngle: endAngle,
                                clockwise: false
                            )
                            // Внутренняя дуга для замыкания формы
                            path.addArc(
                                center: center,
                                radius: radius - 40,  // Значительно увеличиваем внутренний радиус
                                startAngle: endAngle,
                                endAngle: startAngle,
                                clockwise: true
                            )
                            path.closeSubpath()
                        }
                    )
                    // Добавляем отдельный contentShape для предпросмотра при перетаскивании
                    .contentShape(.dragPreview, Circle().scale(1.2))
                    .gesture(
                        TapGesture()
                            .onEnded {
                                withAnimation {
                                    if viewModel.isEditingMode, viewModel.editingTask?.id == task.id
                                    {
                                        viewModel.isEditingMode = false
                                        viewModel.editingTask = nil
                                    } else {
                                        viewModel.isEditingMode = true
                                        viewModel.editingTask = task
                                    }
                                }
                            }
                    )
                    // Добавляем возможность перетаскивания с предпросмотром
                    .onDrag {
                        // Если мы не в режиме редактирования и не в процессе перетаскивания - разрешаем
                        if !viewModel.isEditingMode && viewModel.editingTask == nil && !isDragging {
                            print("onDrag: начало перетаскивания \(task.category.rawValue)")

                            // Начинаем перетаскивание
                            viewModel.startDragging(task)

                            // Устанавливаем флаг перетаскивания
                            isDragging = true

                            // Возвращаем провайдер
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        }
                        print("onDrag: блокировка повторного перетаскивания \(task.category.rawValue)")
                        return NSItemProvider()
                    } preview: {
                        // Максимально простой preview для быстрой загрузки
                        return RoundedRectangle(cornerRadius: 12)
                            .fill(task.category.color)
                            .frame(width: 50, height: 50)
                            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                VStack {
                                    Image(systemName: task.category.iconName)
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                }
                            )
                    }

                    // Если текущая задача в режиме редактирования — показываем маркеры
                    if viewModel.isEditingMode && task.id == viewModel.editingTask?.id {
                        // Маркер начала
                        Circle()
                            .fill(task.category.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                            .position(
                                // Защита от NaN
                                x: center.x + safeMultiply((radius + 10), cos(startAngle.radians)),
                                y: center.y + safeMultiply((radius + 10), sin(startAngle.radians))
                            )
                            .animation(.none, value: startAngle)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        viewModel.isDraggingStart = true
                                        let newTime = viewModel.clockState.timeForLocation(
                                            value.location,
                                            screenWidth: UIScreen.main.bounds.width
                                        )
                                        viewModel.previewTime = newTime

                                        // Обновляем время начала текущей задачи и проверяем пересечения
                                        adjustTaskStartTimesForOverlap(task, newStartTime: newTime)
                                    }
                                    .onEnded { _ in
                                        // Сохраняем обновленное время для редактируемой задачи
                                        if let updatedTask = viewModel.editingTask {
                                            // Найдем актуальную задачу в списке (она могла обновиться)
                                            if let actualTask = viewModel.tasks.first(where: {
                                                $0.id == updatedTask.id
                                            }) {
                                                viewModel.editingTask = actualTask
                                            }
                                        }
                                        viewModel.isDraggingStart = false
                                        viewModel.previewTime = nil
                                    }
                            )

                        // Маркер конца
                        Circle()
                            .fill(task.category.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                            .position(
                                // Защита от NaN
                                x: center.x + safeMultiply((radius + 10), cos(endAngle.radians)),
                                y: center.y + safeMultiply((radius + 10), sin(endAngle.radians))
                            )
                            .animation(.none, value: endAngle)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        viewModel.isDraggingEnd = true
                                        let newTime = viewModel.clockState.timeForLocation(
                                            value.location,
                                            screenWidth: UIScreen.main.bounds.width
                                        )
                                        viewModel.previewTime = newTime

                                        // Обновляем время окончания текущей задачи и проверяем пересечения
                                        adjustTaskEndTimesForOverlap(task, newEndTime: newTime)
                                    }
                                    .onEnded { _ in
                                        // Сохраняем обновленное время для редактируемой задачи
                                        if let updatedTask = viewModel.editingTask {
                                            // Найдем актуальную задачу в списке (она могла обновиться)
                                            if let actualTask = viewModel.tasks.first(where: {
                                                $0.id == updatedTask.id
                                            }) {
                                                viewModel.editingTask = actualTask
                                            }
                                        }
                                        viewModel.isDraggingEnd = false
                                        viewModel.previewTime = nil
                                    }
                            )
                    }

                    // Иконка категории на середине дуги
                    Image(systemName: task.category.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(task.category.color)
                                .frame(width: 20, height: 20)
                        )
                        .position(
                            x: center.x + (radius + 20) * CGFloat(cos(midAngle.radians)),
                            y: center.y + (radius + 20) * CGFloat(sin(midAngle.radians))
                        )
                        // Добавляем идентификатор, чтобы заставить переотрисовываться при изменении zeroPosition
                        .id("task-icon-\(task.id)-\(viewModel.zeroPosition)")
                }
            }
            .onChange(of: isDragging) { oldValue, newValue in
                // Защита от повторных вызовов
                if oldValue == newValue { return }

                // Когда начинается перетаскивание
                if newValue && task.id == viewModel.draggedTask?.id {
                    print("onChange: начало перетаскивания \(task.category.rawValue)")

                    // Проверяем, не скрыта ли уже дуга
                    if isVisible {
                        // Отложенное скрытие дуги
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Проверяем, что перетаскивание все еще активно и дуга все еще видима
                            if isDragging && viewModel.draggedTask?.id == task.id && isVisible {
                                print("onChange: скрываем дугу \(task.category.rawValue)")
                                viewModel.taskManagement.removeTask(task)
                                isVisible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // Вспомогательный метод для безопасного умножения (предотвращает NaN)
    func safeMultiply(_ value1: CGFloat, _ value2: CGFloat) -> CGFloat {
        // Проверка на NaN и бесконечность
        if value1.isNaN || value2.isNaN || value1.isInfinite || value2.isInfinite {
            return 0  // Безопасное значение по умолчанию
        }
        return value1 * value2
    }

    /// Обновляет время начала текущей задачи и сдвигает конфликтующие задачи
    func adjustTaskStartTimesForOverlap(_ currentTask: TaskOnRing, newStartTime: Date) {
        // Обновляем текущую задачу
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
            currentTask, newStartTime: newStartTime)

        // Получаем обновленную версию текущей задачи
        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        // Проверяем наложения с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            // Если время начала updatedTask попадает внутрь otherTask
            if updatedTask.startTime >= otherTask.startTime
                && updatedTask.startTime < otherTask.endTime
            {
                // Сдвигаем время окончания конфликтующей задачи к времени начала редактируемой задачи
                viewModel.taskManagement.updateTaskDuration(
                    otherTask, newEndTime: updatedTask.startTime)
            }
        }
    }

    /// Обновляет время окончания текущей задачи и сдвигает конфликтующие задачи
    func adjustTaskEndTimesForOverlap(_ currentTask: TaskOnRing, newEndTime: Date) {
        // Обновляем текущую задачу
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        // Получаем обновленную версию текущей задачи
        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        // Проверяем наложения с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            // Если время окончания updatedTask попадает внутрь otherTask
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime
            {
                // Сдвигаем время начала конфликтующей задачи к времени окончания редактируемой задачи
                viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                    otherTask, newStartTime: updatedTask.endTime)
            }
        }
    }
}
