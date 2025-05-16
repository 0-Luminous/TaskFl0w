import SwiftUI

struct DockBarView: View {
    @Binding var showClockControls: Bool
    @Binding var showColorControls: Bool
    @Binding var showOuterRingWidthControls: Bool
    @Binding var showArcAnalogToggle: Bool
    @Binding var showMarkersControls: Bool
    @Binding var showZeroPositionControls: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation {
                    showClockControls.toggle()
                    if showClockControls {
                        showArcAnalogToggle = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                        showZeroPositionControls = false
                    }
                }
            }) {
                Image(systemName: "clock")
                    .dockButtonStyle(isSelected: showClockControls)
            }

            Button(action: {
                withAnimation {
                    showMarkersControls.toggle()
                    if showMarkersControls {
                        showClockControls = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showArcAnalogToggle = false
                        showZeroPositionControls = false
                    }
                }
            }) {
                Image(systemName: "slowmo")
                    .dockButtonStyle(isSelected: showMarkersControls)
            }

            Button(action: {
                withAnimation {
                    showColorControls.toggle()
                    if showColorControls {
                        showClockControls = false
                        showArcAnalogToggle = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                        showZeroPositionControls = false
                    }
                }
            }) {
                Image(systemName: "paintpalette")
                    .dockButtonStyle(isSelected: showColorControls)
            }

            Button(action: {
                withAnimation {
                    showOuterRingWidthControls.toggle()
                    if showOuterRingWidthControls {
                        showClockControls = false
                        showColorControls = false
                        showArcAnalogToggle = false
                        showMarkersControls = false
                        showZeroPositionControls = false
                    }
                }
            }) {
                Image(systemName: "clock.circle")
                    .dockButtonStyle(isSelected: showOuterRingWidthControls)
            }

            // Button(action: {
            //     withAnimation {
            //         showZeroPositionControls.toggle()
            //         if showZeroPositionControls {
            //             showClockControls = false
            //             showColorControls = false
            //             showOuterRingWidthControls = false
            //             showMarkersControls = false
            //             showArcAnalogToggle = false
            //         }
            //     }
            // }) {
            //     Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            //         .dockButtonStyle(isSelected: showZeroPositionControls)
            // }

            Button(action: {
                withAnimation {
                    showArcAnalogToggle.toggle()
                    if showArcAnalogToggle {
                        showClockControls = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                        showZeroPositionControls = false
                    }
                }
            }) {
                Image(systemName: "gearshape")
                    .dockButtonStyle(isSelected: showArcAnalogToggle)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 16)
        .frame(width: UIScreen.main.bounds.width * 0.95)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.isDarkMode ? 
                    Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95) : 
                    Color(red: 0.98, green: 0.98, blue: 0.98))
                .shadow(radius: 8)
        )
        .padding(.bottom, 24)
    }
}