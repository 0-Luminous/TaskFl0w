//
//  NewSettingsView.swift
//  TaskFl0w
//
//  Created by Yan on 25/4/25.
//

import SwiftUI

struct SettingsCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

struct NewSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var selectedTitle = ""
    @State private var appeared = [false, false, false, false]
    @State private var showPersonalization = false
    @ObservedObject var viewModel: ClockViewModel

    private let cards: [SettingsCard] = [
        .init(icon: "person.crop.circle", title: "Профиль"),
        .init(icon: "paintbrush", title: "Оформление"),
        .init(icon: "bell", title: "Уведомления"),
        .init(icon: "globe", title: "Язык")
    ]

    private var cardSize: CGFloat {
        let width = UIScreen.main.bounds.width
        if width > 600 { return 220 }
        if width > 400 { return 160 }
        return 120
    }

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.098, blue: 0.098)
                .ignoresSafeArea()
            ScrollView {
                let enumeratedCards = Array(cards.enumerated())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: cardSize), spacing: 28)], spacing: 28) {
                    ForEach(enumeratedCards, id: \.element.id) { idx, card in
                        ZStack {
                            CardView(
                                icon: card.icon,
                                title: card.title
                            )
                            .onTapGesture {
                                if card.title == "Оформление" {
                                    showPersonalization = true
                                } else {
                                    selectedTitle = card.title
                                    showAlert = true
                                }
                            }
                            .opacity(appeared[idx] ? 1 : 0)
                            .onAppear {
                                withAnimation {
                                    appeared[idx] = true
                                }
                            }
                            if card.title == "Оформление" {
                                NavigationLink(
                                    destination: PersonalizationViewIOS(viewModel: viewModel),
                                    isActive: $showPersonalization
                                ) {
                                    EmptyView()
                                }
                                .hidden()
                            }
                        }
                    }
                }
                .padding(.top, 36)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Настройки")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Назад", systemImage: "chevron.left")
                }
                .foregroundColor(.coral1)
            }
        }
        .alert("Вы выбрали: \(selectedTitle)", isPresented: $showAlert) {
            Button("ОК", role: .cancel) { }
        }
    }
}

