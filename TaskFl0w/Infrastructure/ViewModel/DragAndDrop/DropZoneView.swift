//
//  DropZoneView.swift
//  TaskFl0w
//
//  Created by Yan on 25/4/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DropZoneView: UIViewRepresentable {
    @Binding var isTargeted: Bool
    var acceptedTypes: [UTType] = [.text]
    var onEntered: (() -> Void)?
    var onExited: (() -> Void)?
    var onDrop: ((UIDropSession) -> Bool)?
    
    // MARK: - Configuration
    struct Configuration {
        let acceptedTypes: [UTType]
        let allowsMultipleItems: Bool
        let animationDuration: TimeInterval
        
        static let `default` = Configuration(
            acceptedTypes: [.text],
            allowsMultipleItems: false,
            animationDuration: 0.2
        )
    }
    
    private let configuration: Configuration
    
    init(
        isTargeted: Binding<Bool>,
        configuration: Configuration = .default,
        onEntered: (() -> Void)? = nil,
        onExited: (() -> Void)? = nil,
        onDrop: ((UIDropSession) -> Bool)? = nil
    ) {
        self._isTargeted = isTargeted
        self.configuration = configuration
        self.onEntered = onEntered
        self.onExited = onExited
        self.onDrop = onDrop
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let dropInteraction = UIDropInteraction(delegate: context.coordinator)
        view.addInteraction(dropInteraction)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Обновляем конфигурацию если нужно
    }

    class Coordinator: NSObject, UIDropInteractionDelegate {
        let parent: DropZoneView

        init(_ parent: DropZoneView) {
            self.parent = parent
        }

        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            guard session.items.count <= (parent.configuration.allowsMultipleItems ? 10 : 1) else {
                return false
            }
            
            return session.hasItemsConforming(toTypeIdentifiers: 
                parent.configuration.acceptedTypes.map { $0.identifier }
            )
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: self.parent.configuration.animationDuration)) {
                    self.parent.isTargeted = true
                }
                self.parent.onEntered?()
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: self.parent.configuration.animationDuration)) {
                    self.parent.isTargeted = false
                }
                self.parent.onExited?()
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isTargeted = false
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            let success = parent.onDrop?(session) ?? false
            
            if success {
                DispatchQueue.main.async {
                    // Добавляем haptic feedback при успешном drop
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
}

