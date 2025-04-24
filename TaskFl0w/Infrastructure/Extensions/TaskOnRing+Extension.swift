//
//  TaskOnRing+Extension.swift
//  TaskFl0w
//
//  Created by Yan on 24/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

// Определяем тип для передачи TaskOnRing
extension UTType {
    static var taskOnRing: UTType {
        UTType(exportedAs: "com.yan.taskflow.taskonring")
    }
}

// Расширяем TaskOnRing для поддержки протокола Transferable
extension TaskOnRing: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { task in
            // Возвращаем идентификатор задачи в качестве представления для перетаскивания
            return task.id.uuidString
        }
    }
}
