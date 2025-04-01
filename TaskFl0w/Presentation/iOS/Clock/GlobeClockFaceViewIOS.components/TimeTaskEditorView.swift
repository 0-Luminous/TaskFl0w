//
//  TimeTaskEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//

import SwiftUI

struct TimeTaskEditorOverlay: View {
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        ZStack {
            // Основной круг-подложка с серой окантовкой
            Circle()
                .stroke(Color(red: 0.655, green: 0.639, blue: 0.639), lineWidth: 2)
                .frame(width: 170, height: 170)

            // Внутренний темный круг
            Circle()
                .fill(Color(red: 0.192, green: 0.192, blue: 0.192))  // #313131
                .frame(width: 170, height: 170)

            VStack(spacing: 20) {
                // Picker времени начала
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1)

                // Picker времени окончания
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1)
            }
            .padding()
        }
    }
}
