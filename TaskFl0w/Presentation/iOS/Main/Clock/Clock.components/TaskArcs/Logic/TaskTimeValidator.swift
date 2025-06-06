//
//  TaskTimeValidator.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskTimeValidator {
    
    static func validateTimeChange(viewModel: ClockViewModel, newTime: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        return newTime >= startOfDay && newTime <= endOfDay
    }
    
    static func isTimeSlotFree(
        startTime: Date, 
        endTime: Date, 
        excludingTask: TaskOnRing,
        tasks: [TaskOnRing],
        dayBounds: (start: Date, end: Date)
    ) -> Bool {
        guard startTime >= dayBounds.start && endTime <= dayBounds.end else { return false }
        
        for task in tasks where task.id != excludingTask.id {
            if startTime < task.endTime && endTime > task.startTime {
                return false
            }
        }
        return true
    }
    
    static func getDayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        return (start: startOfDay, end: endOfDay)
    }
} 