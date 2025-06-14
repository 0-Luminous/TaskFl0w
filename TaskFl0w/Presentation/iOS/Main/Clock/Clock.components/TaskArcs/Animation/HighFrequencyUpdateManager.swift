//
//  HighFrequencyUpdateManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import UIKit

final class HighFrequencyUpdateManager: ObservableObject {
    private var displayLink: CADisplayLink?
    private weak var viewModel: ClockViewModel?
    
    @Published var isHighFrequencyMode = false
    
    init(viewModel: ClockViewModel) {
        self.viewModel = viewModel
    }
    
    func startHighFrequencyUpdates() {
        guard displayLink == nil else { return }
        
        isHighFrequencyMode = true
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 120
        displayLink?.add(to: .main, forMode: .common)
        
    }
    
    func stopHighFrequencyUpdates() {
        displayLink?.invalidate()
        displayLink = nil
        
        isHighFrequencyMode = false
    }
    
    @objc private func updateFrame() {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.objectWillChange.send()
        }
    }
    
    deinit {
        stopHighFrequencyUpdates()
    }
} 