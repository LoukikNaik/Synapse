import SwiftUI

struct DiagramView: View {
    let data: DiagramData
    @State private var nodePositions: [String: CGPoint] = [:]

    var body: some View {
        Canvas { context, size in
            let positions = calculatePositions(in: size)

            // Draw edges
            for edge in data.edges {
                guard let from = positions[edge.from],
                      let to = positions[edge.to] else { continue }

                drawEdge(context: context, from: from, to: to, label: edge.label)
            }

            // Draw nodes
            for node in data.nodes {
                guard let pos = positions[node.id] else { continue }
                drawNode(context: context, node: node, at: pos)
            }
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func calculatePositions(in size: CGSize) -> [String: CGPoint] {
        let nodes = data.nodes
        guard !nodes.isEmpty else { return [:] }

        // Use topological-inspired layout
        // Build adjacency for layering
        var inDegree: [String: Int] = [:]
        var adjacency: [String: [String]] = [:]
        for node in nodes {
            inDegree[node.id] = 0
            adjacency[node.id] = []
        }
        for edge in data.edges {
            adjacency[edge.from, default: []].append(edge.to)
            inDegree[edge.to, default: 0] += 1
        }

        // Simple layered layout using modified Kahn's algorithm
        var layers: [[String]] = []
        var remaining = Set(nodes.map(\.id))
        var currentInDegree = inDegree

        while !remaining.isEmpty {
            // Find nodes with in-degree 0 (or minimum if cycle)
            let minDegree = remaining.map { currentInDegree[$0] ?? 0 }.min() ?? 0
            let layer = remaining.filter { (currentInDegree[$0] ?? 0) == minDegree }
                .sorted()

            layers.append(layer)
            for nodeID in layer {
                remaining.remove(nodeID)
                for neighbor in adjacency[nodeID] ?? [] {
                    currentInDegree[neighbor, default: 0] -= 1
                }
            }
        }

        // Position nodes in layers
        var positions: [String: CGPoint] = [:]
        let padding: CGFloat = 60
        let usableWidth = size.width - padding * 2
        let usableHeight = size.height - padding * 2
        let layerSpacing = layers.count > 1 ? usableHeight / CGFloat(layers.count - 1) : 0

        for (layerIdx, layer) in layers.enumerated() {
            let nodeSpacing = layer.count > 1 ? usableWidth / CGFloat(layer.count - 1) : 0
            for (nodeIdx, nodeID) in layer.enumerated() {
                let x = layer.count == 1 ? size.width / 2 : padding + CGFloat(nodeIdx) * nodeSpacing
                let y = layers.count == 1 ? size.height / 2 : padding + CGFloat(layerIdx) * layerSpacing
                positions[nodeID] = CGPoint(x: x, y: y)
            }
        }

        return positions
    }

    private func drawNode(context: GraphicsContext, node: DiagramNode, at point: CGPoint) {
        let radius: CGFloat = 35
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)

        // Node circle
        let color: Color = node.type == "primary" ? .blue : (node.type == "highlight" ? .orange : .gray)
        let path = Path(ellipseIn: rect)
        context.fill(path, with: .color(color.opacity(0.2)))
        context.stroke(path, with: .color(color), lineWidth: 2)

        // Node label
        let text = Text(node.label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.primary)
        context.draw(text, at: point, anchor: .center)
    }

    private func drawEdge(context: GraphicsContext, from: CGPoint, to: CGPoint, label: String?) {
        let nodeRadius: CGFloat = 35

        // Calculate edge endpoints at node boundaries
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return }

        let unitX = dx / distance
        let unitY = dy / distance

        let startPoint = CGPoint(x: from.x + unitX * nodeRadius, y: from.y + unitY * nodeRadius)
        let endPoint = CGPoint(x: to.x - unitX * nodeRadius, y: to.y - unitY * nodeRadius)

        // Draw line
        var linePath = Path()
        linePath.move(to: startPoint)
        linePath.addLine(to: endPoint)
        context.stroke(linePath, with: .color(.secondary), lineWidth: 1.5)

        // Draw arrowhead
        let arrowSize: CGFloat = 10
        let angle = atan2(dy, dx)
        let arrowP1 = CGPoint(
            x: endPoint.x - arrowSize * cos(angle - .pi / 6),
            y: endPoint.y - arrowSize * sin(angle - .pi / 6)
        )
        let arrowP2 = CGPoint(
            x: endPoint.x - arrowSize * cos(angle + .pi / 6),
            y: endPoint.y - arrowSize * sin(angle + .pi / 6)
        )
        var arrowPath = Path()
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowP1)
        arrowPath.addLine(to: arrowP2)
        arrowPath.closeSubpath()
        context.fill(arrowPath, with: .color(.secondary))

        // Draw edge label
        if let label {
            let midPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2 - 8)
            let text = Text(label).font(.system(size: 8)).foregroundColor(.secondary)
            context.draw(text, at: midPoint, anchor: .center)
        }
    }
}
