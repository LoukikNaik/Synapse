import SwiftUI

struct MasteryRingView: View {
    let mastery: Double
    @State private var animatedMastery: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedMastery)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .purple, .blue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 4) {
                Text("\(Int(animatedMastery * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Mastery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedMastery = mastery
            }
        }
        .onChange(of: mastery) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedMastery = newValue
            }
        }
    }
}
