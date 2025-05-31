//
//  TaskArcShape.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskArcShape: View {
    let geometry: TaskArcGeometry
    
    var body: some View {
        geometry.createArcPath()
            .stroke(
                geometry.task.category.color, 
                lineWidth: geometry.configuration.arcLineWidth
            )
            .contentShape(.interaction, geometry.createGestureArea())
            .contentShape(.dragPreview, geometry.createDragPreviewArea())
    }
} 