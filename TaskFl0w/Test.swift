//
//  Test.swift
//  TaskFl0w
//
//  Created by Yan on 3/6/25.
//

import SwiftUI

struct DraggableShape: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isCircle: Bool
}

struct TwoDropZonesView: View {
    @State private var shapes: [DraggableShape] = [
        DraggableShape(position: CGPoint(x: 100, y: 100), isCircle: false)
    ]
    @State private var draggedShapeID: UUID?
    
    // Зоны
    let zone1 = CGRect(x: 0, y: 0, width: 200, height: 400)
    let zone2 = CGRect(x: 220, y: 0, width: 200, height: 400)

    var body: some View {
        ZStack {
            // Зона 1
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: zone1.width, height: zone1.height)
                .position(x: zone1.midX, y: zone1.midY)
                .overlay(Text("Зона 1"))
            
            // Зона 2
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .frame(width: zone2.width, height: zone2.height)
                .position(x: zone2.midX, y: zone2.midY)
                .overlay(Text("Зона 2"))
            
            ForEach(shapes.indices, id: \.self) { index in
                let shape = shapes[index]
                
                Group {
                    if shape.isCircle {
                        Circle()
                            .fill(Color.red)
                    } else {
                        Rectangle()
                            .fill(Color.red)
                    }
                }
                .frame(width: 60, height: 60)
                .position(shape.position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            draggedShapeID = shape.id
                            withAnimation(.interactiveSpring()) {
                                shapes[index].position = value.location
                                
                                // Проверка на попадание в зону 2
                                if zone2.contains(value.location) {
                                    shapes[index].isCircle = true
                                } else if zone1.contains(value.location) {
                                    shapes[index].isCircle = false
                                }
                            }
                        }
                        .onEnded { value in
                            let newPos = value.location
                            shapes[index].position = newPos
                        }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: shapes.map { $0.isCircle })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
