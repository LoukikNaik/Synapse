import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(level <= difficulty ? badgeColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch difficulty {
        case 1...2: return .green
        case 3: return .orange
        default: return .red
        }
    }
}
