//
//  EnhancedAddWatchFaceView.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI


// Улучшенный экран добавления циферблата
struct EnhancedAddWatchFaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @ObservedObject private var clockViewModel = ClockViewModel()
    @ObservedObject private var markersViewModel = ClockMarkersViewModel()
    @State private var watchFaceName = ""
    @State private var currentDate = Date()
    @State private var tasks: [TaskOnRing] = []
    @State private var viewModel = ClockViewModel()
    @State private var draggedCategory: TaskCategoryModel?
    @State private var zeroPosition: Double = 0
    @State private var taskArcLineWidth: CGFloat = 2
    @State private var outerRingLineWidth: CGFloat = 20
    
        
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.098, green: 0.098, blue: 0.092)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Название циферблата", text: $watchFaceName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Text("Предпросмотр")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ZStack {
                            GlobleClockFaceViewIOS(
                                currentDate: currentDate,
                                tasks: tasks,
                                viewModel: viewModel,
                                markersViewModel: markersViewModel,
                                draggedCategory: $draggedCategory,
                                zeroPosition: zeroPosition,
                                taskArcLineWidth: taskArcLineWidth,
                                outerRingLineWidth: outerRingLineWidth
                            )

                        .frame(width: 200, height: 200)
                        
                        RingPlanner(
                            color: .gray.opacity(0.3),
                            viewModel: clockViewModel,
                            zeroPosition: 0,
                            shouldDeleteTask: false,
                            outerRingLineWidth: 20
                        )
                        .frame(width: 200, height: 200)
                    }
                    .padding(.vertical, 50)
                    
                    Text("Сохраните текущие настройки как новый пользовательский циферблат")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        if !watchFaceName.isEmpty {
                            libraryManager.createCustomWatchFace(name: watchFaceName)
                            dismiss()
                        }
                    } label: {
                        Text("Сохранить")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                !watchFaceName.isEmpty
                                    ? LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(watchFaceName.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("Новый циферблат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Отмена")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
} 
