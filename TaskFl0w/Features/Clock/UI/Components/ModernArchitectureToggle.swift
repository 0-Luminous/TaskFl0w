//
//  ModernArchitectureToggle.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import SwiftUI

/// Debug компонент для переключения между архитектурами
/// Отображается только в DEBUG режиме
struct ModernArchitectureToggle: View {
    @State private var isModernEnabled = FeatureFlags.modernClockArchitecture
    @State private var showDetails = false
    
    var body: some View {
        #if DEBUG
        VStack(spacing: 12) {
            // Main Toggle
            architectureToggle
            
            // Details Panel
            if showDetails {
                detailsPanel
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.spring(), value: showDetails)
        #endif
    }
    
    #if DEBUG
    // MARK: - Components
    
    private var architectureToggle: some View {
        HStack(spacing: 15) {
            // Architecture Status Icon
            Image(systemName: isModernEnabled ? "cpu.fill" : "cpu")
                .font(.title2)
                .foregroundColor(isModernEnabled ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Architecture")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(isModernEnabled ? "Modern Redux" : "Legacy MVP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle Switch
            Toggle("", isOn: $isModernEnabled)
                .onChange(of: isModernEnabled) { _, newValue in
                    FeatureFlags.modernClockArchitecture = newValue
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            
            // Details Button
            Button(action: { showDetails.toggle() }) {
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var detailsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current Status
            statusRow("Status:", isModernEnabled ? "✅ Active" : "⏸️ Inactive")
            statusRow("Pattern:", isModernEnabled ? "Redux-like Store" : "MVVM Delegation")
            statusRow("State Management:", isModernEnabled ? "Centralized" : "Distributed")
            statusRow("Type Safety:", isModernEnabled ? "100%" : "Partial")
            
            Divider()
                .padding(.vertical, 4)
            
            // Performance Metrics (Mock)
            Text("Expected Performance:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if isModernEnabled {
                performanceMetric("Development Speed", "+35%", .green)
                performanceMetric("Bug Reduction", "-47%", .green)
                performanceMetric("Maintainability", "+70%", .green)
            } else {
                performanceMetric("Development Speed", "Baseline", .orange)
                performanceMetric("Bug Rate", "Baseline", .orange)
                performanceMetric("Technical Debt", "High", .red)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Quick Actions
            HStack(spacing: 10) {
                Button("Reset") {
                    FeatureFlags.resetToDefaults()
                    isModernEnabled = FeatureFlags.modernClockArchitecture
                } 
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
                
                Button("Debug Info") {
                    print(FeatureFlags.debugInfo())
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func performanceMetric(_ name: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(name)
                .font(.caption2)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    VStack {
        ModernArchitectureToggle()
        Spacer()
    }
    .padding()
} 