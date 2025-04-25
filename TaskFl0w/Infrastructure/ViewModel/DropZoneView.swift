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
    var onEntered: (() -> Void)?
    var onExited: (() -> Void)?
    var onDrop: (() -> Void)?

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

    func updateUIView(_ uiView: UIView, context: Context) {}

    class Coordinator: NSObject, UIDropInteractionDelegate {
        let parent: DropZoneView

        init(_ parent: DropZoneView) {
            self.parent = parent
        }

        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            // Здесь можно фильтровать по типу, если нужно
            return true // или false, если хотите полностью игнорировать drop
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isTargeted = true
                self.parent.onEntered?()
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isTargeted = false
                self.parent.onExited?()
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isTargeted = false
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.onDrop?()
            }
        }
    }
}

