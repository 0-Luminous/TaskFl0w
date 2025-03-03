//
//  TaskFl0wApp.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct TaskFl0wApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                ClockViewIpad()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                ClockViewIOS()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
            #else
            Text("Unsupported Platform")
            #endif
        }
    }
}
