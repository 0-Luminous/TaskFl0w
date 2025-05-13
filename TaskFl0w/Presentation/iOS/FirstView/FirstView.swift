//
//  FirstView.swift
//  TaskFl0w
//
//  Created by Yan on 11/5/25.
//

import SwiftUI

struct FirstView: View {
    @State private var isAnimating = false
    @State private var showButton = false
    @State private var selectedWatchFace: WatchFaceModel?
    @State private var navigateToLibrary = false
    @State private var navigateToSelectCategory = false
    
    // Массив предустановленных циферблатов
    private let watchFaces = WatchFaceModel.defaultWatchFaces
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Удаляем Spacer() отсюда
                    
                    // Кнопка выбора циферблата размещается внизу экрана
                    Spacer()
                    
                    if showButton {
                        Button(action: {
                            navigateToSelectCategory = true
                        }) {
                            Text("Выбрать стартовые категории")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(radius: 5)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(10) // Чтобы кнопка была поверх циферблатов
                    }
                    
                    Spacer().frame(height: 20)
                }
                
                // Анимированные дуги категорий (вынесены из VStack)
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        CategoryArcView(
                            radius: CGFloat.random(in: 80...180),
                            thickness: CGFloat.random(in: 8...18),
                            startAngle: .degrees(Double.random(in: 0...180)),
                            endAngle: .degrees(Double.random(in: 200...360)),
                            color: [Color.pink, Color.blue, Color.purple, Color.green, Color.orange][i % 5],
                            animationDuration: Double.random(in: 3.5...6.5),
                            maxOffset: 120
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Анимированные циферблаты (вынесены из VStack)
                ZStack {
                    ForEach(Array(watchFaces.enumerated()), id: \.1.id) { (idx, face) in
                        AnimatedFlyingWatchFaceView(
                            watchFace: face,
                            index: idx,
                            isAnimating: isAnimating
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $navigateToLibrary) {
                LibraryOfWatchFaces()
            }
            .navigationDestination(isPresented: $navigateToSelectCategory) {
                SelectCategory()
            }
            .onAppear {
                // Запускаем анимацию при появлении
                withAnimation {
                    isAnimating = true
                }
                
                // Показываем кнопку с задержкой
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showButton = true
                    }
                }
            }
        }
    }
}

struct CategoryArcView: View {
    @State private var animating = false
    let radius: CGFloat
    let thickness: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let animationDuration: Double
    let maxOffset: CGFloat
    
    var body: some View {
        ArcShape(startAngle: startAngle, endAngle: endAngle)
            .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(animating ? .degrees(Double.random(in: 0...360)) : .zero)
            .offset(x: animating ? CGFloat.random(in: -maxOffset...maxOffset) : 0,
                    y: animating ? CGFloat.random(in: -maxOffset...maxOffset) : 0)
            .blur(radius: 2)
            .shadow(color: color.opacity(0.4), radius: 8)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                    animating = true
                }
            }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center, radius: radius, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        return path
    }
}

struct AnimatedFlyingWatchFaceView: View {
    let watchFace: WatchFaceModel
    let index: Int
    let isAnimating: Bool
    @State private var randomOffset: CGSize = .zero
    @State private var randomRotation: Double = 0
    @State private var randomScale: CGFloat = 0.3

    func randomize() {
        randomOffset = CGSize(width: CGFloat.random(in: -180...180), height: CGFloat.random(in: -300...300))
        randomRotation = Double.random(in: -60...60)
        randomScale = CGFloat.random(in: 0.2...0.4)
    }

    func animateForever() {
        guard isAnimating else { return }
        let duration = Double.random(in: 7.0...12.0)
        withAnimation(Animation.easeInOut(duration: duration)) {
            randomize()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            animateForever()
        }
    }

    var body: some View {
        ZStack {
            LibraryClockFaceView(watchFace: watchFace)
            RingPlanner(
                color: .white.opacity(0.25),
                viewModel: ClockViewModel(),
                zeroPosition: 0,
                shouldDeleteTask: false,
                outerRingLineWidth: 20
            )
        }
        .scaleEffect(randomScale)
        .rotationEffect(.degrees(randomRotation))
        .offset(randomOffset)
        .onAppear {
            randomize()
            if isAnimating {
                animateForever()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                animateForever()
            }
        }
    }
}


