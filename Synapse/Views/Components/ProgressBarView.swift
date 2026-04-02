import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var color: Color = .blue
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * min(1, progress)), height: height)
            }
        }
        .frame(height: height)
    }
}
