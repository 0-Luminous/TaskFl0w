//
//  HighFrequencyUpdateManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import UIKit

/// Менеджер для высокочастотного обновления UI во время перетаскивания маркеров
final class HighFrequencyUpdateManager: ObservableObject {
    private var displayLink: CADisplayLink?
    private weak var viewModel: ClockViewModel?
    
    @Published var isHighFrequencyMode = false
    
    init(viewModel: ClockViewModel) {
        self.viewModel = viewModel
    }
    
    /// Запускает высокочастотное обновление с максимальной частотой кадров
    func startHighFrequencyUpdates() {
        guard displayLink == nil else { return }
        
        isHighFrequencyMode = true
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 120 // Максимальная частота для ProMotion
        displayLink?.add(to: .main, forMode: .common)
        
        print("🚀 Запущено высокочастотное обновление с частотой 120 FPS")
    }
    
    /// Останавливает высокочастотное обновление
    func stopHighFrequencyUpdates() {
        displayLink?.invalidate()
        displayLink = nil
        
        isHighFrequencyMode = false
        
        print("⏹️ Остановлено высокочастотное обновление")
    }
    
    @objc private func updateFrame() {
        // Принудительно обновляем ViewModel для перерисовки UI
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.objectWillChange.send()
        }
    }
    
    deinit {
        stopHighFrequencyUpdates()
    }
} 