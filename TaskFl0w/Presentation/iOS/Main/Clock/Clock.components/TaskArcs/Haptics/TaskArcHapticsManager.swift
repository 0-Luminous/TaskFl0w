//
//  TaskArcHapticsManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import UIKit

struct TaskArcHapticsManager {
    func triggerSoftFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerHardFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerSelectionFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerDragFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.5)
    }
} 