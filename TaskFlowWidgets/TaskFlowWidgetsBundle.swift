//
//  TaskFlowWidgetsBundle.swift
//  TaskFlowWidgets
//
//  Created by Yan on 30/4/25.
//

import WidgetKit
import SwiftUI

@main
struct TaskFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskFlowWidgets()
        TaskFlowWidgetsControl()
        TaskFlowWidgetsLiveActivity()
    }
}
