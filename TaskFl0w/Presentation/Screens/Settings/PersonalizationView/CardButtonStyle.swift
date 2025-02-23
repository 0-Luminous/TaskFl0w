//
//  CardButtonStyle.swift
//  TaskFl0w
//
//  Created by Yan on 24/2/25.
//

import SwiftUI
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.blue.opacity(configuration.isPressed ? 0.3 : 0), lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
