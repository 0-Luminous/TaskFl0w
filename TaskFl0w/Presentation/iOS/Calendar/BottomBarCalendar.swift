//
//  BottomBar.swift
//  TaskFl0w
//
//  Created by Yan on 15/4/25.
//

import SwiftUI

struct BottomBarCalendar: View {
    enum ViewMode: String, CaseIterable {
        case week = "WEEK"
        case month = "MONTH"
    }
    
    @Binding var selectedMode: ViewMode
    var onAddButtonTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 0) {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedMode == mode ? .white : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                    }
                }
            }
            .padding(6)
            .background(Color.black.opacity(0.4))
            .cornerRadius(20)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
        .cornerRadius(30)
    }
}

#Preview {
    ZStack {
        Color.gray.edgesIgnoringSafeArea(.all)
        BottomBarCalendar(selectedMode: .constant(.week), onAddButtonTapped: {})
            .padding(.horizontal)
    }
}

