//
//  TaskFl0wApp.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import WidgetKit

#if canImport(UIKit)
    import UIKit
#endif

@main
struct TaskFl0wApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ClockViewIOS()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

#if canImport(WidgetKit)
struct TaskFlowWidgets: WidgetBundle {
    var body: some Widget {
        CategoryWidget()
    }
}
#endif
