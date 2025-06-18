import SwiftUI

struct ClockMarksView: View {
    @StateObject private var viewModel = ClockMarkersViewModel()

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24) { hour in
                ClockMarkView(
                    hour: hour,
                    geometry: geometry,
                    viewModel: viewModel)
            }
        }
    }
}

struct ClockMarkView: View {
    let hour: Int
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ClockMarkersViewModel

    var body: some View {
        Group {
            clockMarkLine
            clockMarkText
        }
    }

    private var clockMarkLine: some View {
        Path { path in
            let angle = CGFloat(hour) * .pi / 12
            let length: CGFloat = hour % 3 == 0 ? 15 : 10
            let start = viewModel.startPoint(angle: angle, length: length, geometry: geometry)
            let end = viewModel.endPoint(angle: angle, geometry: geometry)

            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            viewModel.currentMarkersColor,
            lineWidth: hour % 3 == 0 ? 2 : 1
        )
    }

    private var clockMarkText: some View {
        let position = viewModel.textPosition(hour: hour, geometry: geometry)

        return Text("\(hour)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(viewModel.currentMarkersColor)
            .position(x: position.x, y: position.y)
    }
}
