//
//  LanguagesView.swift
//  TaskFl0w
//
//  Created by Yan on 24/2/25.
//

import SwiftUI

struct Language: Identifiable {
    let id = UUID()
    let name: String
    let code: String
}

struct LanguagesView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "ru"
    
    private let languages = [
        Language(name: "Русский", code: "ru"),
        Language(name: "English", code: "en"),
        Language(name: "中文", code: "zh"),
        Language(name: "Español", code: "es"),
        Language(name: "Deutsch", code: "de")
    ]
    
    var body: some View {
        List {
            ForEach(languages) { language in
                Button(action: {
                    selectedLanguage = language.code
                }) {
                    HStack {
                        Text(language.name)
                        Spacer()
                        if selectedLanguage == language.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Язык")
        .navigationBarTitleDisplayMode(.large)
    }
}

