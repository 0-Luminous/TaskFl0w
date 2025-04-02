import SwiftUI

struct ClockMarker: View {
    let hour: Int
    let style: MarkerStyle
    @ObservedObject var viewModel: ClockMarkersViewModel

    var body: some View {
        VStack(spacing: 0) {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(viewModel.currentMarkersColor)
                    .frame(width: viewModel.markersWidth, height: 12)
                if viewModel.showHourNumbers {
                    Text("\(hour)")
                        .font(.system(size: viewModel.numbersSize))
                        .foregroundColor(viewModel.currentMarkersColor)
                        .rotationEffect(
                            .degrees(-Double(hour) * (360.0 / 24.0) - viewModel.zeroPosition)
                        )
                        .offset(y: 5)
                }

            case .lines:
                Rectangle()
                    .fill(viewModel.currentMarkersColor)
                    .frame(width: viewModel.markersWidth, height: viewModel.markerHeight(for: hour))

            case .dots:
                Circle()
                    .fill(viewModel.currentMarkersColor)
                    .frame(
                        width: viewModel.markerWidth(for: hour),
                        height: viewModel.markerWidth(for: hour))
            }
        }
        .offset(y: viewModel.markerOffset())
    }
}
