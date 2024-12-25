import SwiftUI

struct MainClockMarker: View {
    let hour: Int
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: hour % 3 == 0 ? 3 : 1,
                       height: hour % 3 == 0 ? 15 : 10)
        }
        .offset(y: -UIScreen.main.bounds.width * 0.38)
        .rotationEffect(Angle.degrees(Double(hour) / 24 * 360))
    }
}
