//
//  SettingsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ClockViewModel()
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Тёмный режим", isOn: $isDarkMode)
                } header: {
                    Text("Тема")
                }
                
                Section {
                    NavigationLink(destination: ClockFaceEditorView()) {
                        HStack {
                            Text("Редактировать циферблат")
                            Spacer()
                            Image(systemName: "clock.circle")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        viewModel.showingCategoryEditor = true
                    }) {
                        HStack {
                            Text("Редактировать категории")
                            Spacer()
                            Image(systemName: "folder.badge.gearshape")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Настройки циферблата")
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCategoryEditor) {
                CategoryEditorView(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
        }
    }
}
