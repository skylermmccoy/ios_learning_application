import SwiftUI

/// Draws a teaching card's diagram on a card-coloured panel, with its caption.
/// A `frames` visual becomes a step-through with Back / Next.
struct CardVisualView: View {
    let visual: CardVisual
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            if case .frames(let frames) = visual.kind {
                FramesView(frames: frames, color: color)
            } else {
                VisualContent(visual: visual, color: color)
                if let caption = visual.caption { CaptionText(caption) }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct CaptionText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// One diagram, without panel or caption.
private struct VisualContent: View {
    let visual: CardVisual
    let color: Color

    var body: some View {
        switch visual.kind {
        case .bars(let v): BarsView(bars: v, color: color)
        case .cells(let v): CellsView(cells: v, color: color)
        case .flow(let v): FlowView(flow: v, color: color)
        case .stack(let v): LayersView(stack: v, color: color)
        case .graph(let v): GraphCanvas(graph: v, color: color, caption: visual.caption)
        case .tree(let v): GraphCanvas(tree: v, color: color, caption: visual.caption)
        case .table(let v): TableView(table: v, color: color)
        case .plot(let v): PlotView(plot: v, caption: visual.caption)
        case .timeline(let v): TimelineView(timeline: v, color: color)
        case .icons(let v): IconsView(icons: v, color: color)
        case .compare(let v): CompareView(compare: v, color: color)
        case .frames: EmptyView()   // frames are never nested
        }
    }
}

// MARK: - Step-through

private struct FramesView: View {
    let frames: [CardVisual]
    let color: Color
    @State private var index = 0

    var body: some View {
        let i = min(index, frames.count - 1)
        VStack(spacing: 12) {
            VisualContent(visual: frames[i], color: color)
                .animation(.snappy, value: index)

            // Room for two lines so the buttons don't jump between steps.
            CaptionText(frames[i].caption ?? "")
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .center)

            HStack {
                Button {
                    index = max(0, i - 1)
                } label: {
                    Image(systemName: "chevron.left").frame(width: 30, height: 24)
                }
                .disabled(i == 0)
                .accessibilityLabel("Previous step")

                Spacer()
                Text("Step \(i + 1) of \(frames.count)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    index = i + 1 < frames.count ? i + 1 : 0
                } label: {
                    Label(i + 1 < frames.count ? "Next" : "Replay",
                          systemImage: i + 1 < frames.count ? "chevron.right" : "arrow.counterclockwise")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .frame(height: 24)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(color)
        }
    }
}

// MARK: - Arrays

private func pointerNames(_ pointers: [String: Int]?, at index: Int) -> String {
    (pointers ?? [:]).filter { $0.value == index }.keys.sorted().joined(separator: ",")
}

private func plain(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
}

private struct BarsView: View {
    let bars: CardVisual.Bars
    let color: Color

    var body: some View {
        let top = max(bars.values.max() ?? 1, 1)
        let highlight = Set(bars.highlight ?? []), done = Set(bars.done ?? [])
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(bars.values.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(highlight.contains(i) ? color : done.contains(i) ? Color.green : Color(.systemGray3))
                        .frame(height: 16 + 94 * bars.values[i] / top)
                    Text(bars.labels?[safe: i] ?? plain(bars.values[i]))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if bars.pointers != nil {
                        Text(pointerNames(bars.pointers, at: i))
                            .font(.caption2.bold())
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(height: 13)
                    }
                }
                .frame(maxWidth: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Values " + bars.values.map(plain).joined(separator: ", "))
    }
}

private struct CellsView: View {
    let cells: CardVisual.Cells
    let color: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row
            ScrollView(.horizontal, showsIndicators: false) { row }
        }
        .frame(maxWidth: .infinity)
    }

    private var row: some View {
        let highlight = Set(cells.highlight ?? []), done = Set(cells.done ?? [])
        return HStack(alignment: .top, spacing: 4) {
            ForEach(cells.items.indices, id: \.self) { i in
                let tint: Color? = highlight.contains(i) ? color : done.contains(i) ? .green : nil
                VStack(spacing: 3) {
                    Text(cells.items[i])
                        .font(.system(.callout, design: .monospaced).weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 32, minHeight: 38)
                        .background((tint ?? Color(.systemGray3)).opacity(tint == nil ? 0.35 : 0.28), in: .rect(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint ?? .clear, lineWidth: 2))
                    if cells.indices == true {
                        Text("\(i)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    if cells.pointers != nil {
                        Text(pointerNames(cells.pointers, at: i))
                            .font(.caption2.bold())
                            .foregroundStyle(color)
                            .frame(height: 13)
                    }
                }
                if cells.arrows == true, i + 1 < cells.items.count {
                    Image(systemName: "arrow.right")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(height: 38)
                }
            }
        }
        .fixedSize()
        .padding(2)
    }
}

// MARK: - Steps and layers

private struct FlowView: View {
    let flow: CardVisual.Flow
    let color: Color

    var body: some View {
        let highlight = Set(flow.highlight ?? [])
        VStack(spacing: 4) {
            ForEach(flow.steps.indices, id: \.self) { i in
                let on = highlight.contains(i)
                HStack(spacing: 10) {
                    Text("\(i + 1)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(on ? color : .white)
                        .frame(width: 22, height: 22)
                        .background(on ? Color.white : color, in: .circle)
                    Text(flow.steps[i])
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(on ? .white : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(on ? color : color.opacity(0.14), in: .rect(cornerRadius: 12))
                if i + 1 < flow.steps.count {
                    Image(systemName: "arrow.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct LayersView: View {
    let stack: CardVisual.Layers
    let color: Color

    var body: some View {
        let highlight = Set(stack.highlight ?? [])
        VStack(spacing: 3) {
            ForEach(stack.layers.indices, id: \.self) { i in
                let on = highlight.contains(i)
                Text(stack.layers[i])
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(on ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10).padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(on ? color : color.opacity(0.16), in: .rect(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Graphs and trees

/// Nodes as capsules joined by lines. Trees are laid out here and drawn the same way.
private struct GraphCanvas: View {
    struct Node { let label: String; let unit: CGPoint; let on: Bool }
    struct Edge { let from: Int; let to: Int; let label: String?; let on: Bool }

    let nodes: [Node]
    let edges: [Edge]
    let directed: Bool
    let height: CGFloat
    let color: Color
    let caption: String?

    init(graph: CardVisual.Graph, color: Color, caption: String?) {
        let highlight = Set(graph.highlight ?? [])
        let lit = Set((graph.highlightEdges ?? []).filter { $0.count == 2 }.map { Set($0) })
        let index = Dictionary(graph.nodes.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
        nodes = graph.nodes.map {
            Node(label: $0.label ?? $0.id, unit: CGPoint(x: $0.x, y: $0.y), on: highlight.contains($0.id))
        }
        edges = (graph.edges ?? []).compactMap { e in
            guard let a = index[e.from], let b = index[e.to] else { return nil }
            return Edge(from: a, to: b, label: e.label, on: lit.contains([e.from, e.to]))
        }
        directed = graph.directed ?? false
        height = 210
        self.color = color
        self.caption = caption
    }

    init(tree: CardVisual.Tree, color: Color, caption: String?) {
        let highlight = Set(tree.highlight ?? [])
        var placed: [(label: String, x: Double, depth: Int)] = []
        var links: [(Int, Int)] = []
        var nextSlot = 0.0

        /// Leaves take the next free column; a parent sits midway over its children.
        func place(_ node: CardVisual.Tree.Node, depth: Int) -> Int {
            var childIndices: [Int] = []
            var xs: [Double] = []
            for child in node.children ?? [] {
                if let child {
                    let i = place(child, depth: depth + 1)
                    childIndices.append(i)
                    xs.append(placed[i].x)
                } else {
                    xs.append(nextSlot)
                    nextSlot += 1
                }
            }
            let x: Double
            if let first = xs.first, let last = xs.last {
                x = (first + last) / 2
            } else {
                x = nextSlot
                nextSlot += 1
            }
            placed.append((node.label, x, depth))
            let me = placed.count - 1
            links += childIndices.map { (me, $0) }
            return me
        }
        _ = place(tree.root, depth: 0)

        let maxX = placed.map(\.x).max() ?? 0, maxDepth = placed.map(\.depth).max() ?? 0
        nodes = placed.map {
            Node(label: $0.label,
                 unit: CGPoint(x: maxX == 0 ? 0.5 : $0.x / maxX, y: maxDepth == 0 ? 0.5 : Double($0.depth) / Double(maxDepth)),
                 on: highlight.contains($0.label))
        }
        edges = links.map { Edge(from: $0.0, to: $0.1, label: nil, on: false) }
        directed = false
        height = 64 + 54 * CGFloat(maxDepth)
        self.color = color
        self.caption = caption
    }

    var body: some View {
        Canvas { context, size in
            let inset = CGSize(width: 30, height: 24)
            func point(_ unit: CGPoint) -> CGPoint {
                CGPoint(x: inset.width + unit.x * (size.width - 2 * inset.width),
                        y: inset.height + unit.y * (size.height - 2 * inset.height))
            }
            let texts = nodes.map {
                context.resolve(Text($0.label).font(.caption.bold()).foregroundStyle($0.on ? Color.white : Color.primary))
            }
            let boxes: [CGRect] = nodes.indices.map { i in
                let measured = texts[i].measure(in: size)
                let w = max(30, measured.width + 14), h: CGFloat = 30
                let c = point(nodes[i].unit)
                return CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
            }
            let line = Color(.systemGray2)

            for edge in edges {
                let a = point(nodes[edge.from].unit), b = point(nodes[edge.to].unit)
                let stroke = GraphicsContext.Shading.color(edge.on ? color : line)
                let width: CGFloat = edge.on ? 3.5 : 2

                if edge.from == edge.to {
                    // A loop back to the same node, drawn above it.
                    let loop = CGRect(x: a.x - 12, y: boxes[edge.from].minY - 20, width: 24, height: 26)
                    context.stroke(Path(ellipseIn: loop), with: stroke, lineWidth: width)
                    continue
                }
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: stroke, lineWidth: width)

                let dx = b.x - a.x, dy = b.y - a.y
                let length = max(sqrt(dx * dx + dy * dy), 0.001)
                let ux = dx / length, uy = dy / length
                if directed {
                    // Stop the arrowhead at the edge of the target's box.
                    let box = boxes[edge.to]
                    let reach = min(abs(ux) < 0.001 ? .infinity : (box.width / 2) / abs(ux),
                                    abs(uy) < 0.001 ? .infinity : (box.height / 2) / abs(uy)) + 2
                    let tip = CGPoint(x: b.x - ux * reach, y: b.y - uy * reach)
                    let back = CGPoint(x: tip.x - ux * 10, y: tip.y - uy * 10)
                    var head = Path()
                    head.move(to: tip)
                    head.addLine(to: CGPoint(x: back.x - uy * 5, y: back.y + ux * 5))
                    head.addLine(to: CGPoint(x: back.x + uy * 5, y: back.y - ux * 5))
                    head.closeSubpath()
                    context.fill(head, with: stroke)
                }
                if let label = edge.label {
                    let text = context.resolve(Text(label).font(.caption2.bold())
                        .foregroundStyle(edge.on ? color : Color.secondary))
                    let m = text.measure(in: size)
                    let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                    let plate = CGRect(x: mid.x - m.width / 2 - 4, y: mid.y - m.height / 2 - 2,
                                       width: m.width + 8, height: m.height + 4)
                    context.fill(Path(roundedRect: plate, cornerRadius: 6),
                                 with: .color(Color(.secondarySystemGroupedBackground)))
                    context.draw(text, at: mid)
                }
            }

            for i in nodes.indices {
                let shape = Path(roundedRect: boxes[i], cornerRadius: boxes[i].height / 2)
                context.fill(shape, with: .color(nodes[i].on ? color : Color(.systemGray5)))
                context.stroke(shape, with: .color(nodes[i].on ? color : line), lineWidth: 1.5)
                context.draw(texts[i], at: CGPoint(x: boxes[i].midX, y: boxes[i].midY))
            }
        }
        .frame(height: height)
        .frame(maxWidth: 420)
        .accessibilityElement()
        .accessibilityLabel(caption ?? "Diagram of " + nodes.map(\.label).joined(separator: ", "))
    }
}

// MARK: - Table

private struct TableView: View {
    let table: CardVisual.Table
    let color: Color

    var body: some View {
        let lit = Set((table.highlight ?? []).filter { $0.count == 2 }.map { [$0[0], $0[1]] })
        let litRows = Set(table.highlightRows ?? [])
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            if let headers = table.headers {
                GridRow {
                    ForEach(headers.indices, id: \.self) { c in
                        cell(headers[c], bold: true).background(color.opacity(0.2))
                    }
                }
            }
            ForEach(table.rows.indices, id: \.self) { r in
                GridRow {
                    ForEach(table.rows[r].indices, id: \.self) { c in
                        let on = litRows.contains(r) || lit.contains([r, c])
                        cell(table.rows[r][c], bold: on)
                            .background(on ? color.opacity(0.32) : r % 2 == 1 ? Color(.systemFill).opacity(0.35) : .clear)
                    }
                }
            }
        }
        .clipShape(.rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
    }

    private func cell(_ text: String, bold: Bool) -> some View {
        Text(text)
            .font(.footnote.weight(bold ? .bold : .regular).monospacedDigit())
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 5).padding(.vertical, 7)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Plot

private struct PlotView: View {
    let plot: CardVisual.Plot
    let caption: String?

    private static let palette: [Color] = [.blue, .orange, .green, .purple, .pink]

    var body: some View {
        let points = plot.series.flatMap(\.points).filter { $0.count == 2 }
        let xs = points.map { $0[0] }, ys = points.map { $0[1] }
        let minX = xs.min() ?? 0, maxX = max(xs.max() ?? 1, minX + 0.0001)
        let minY = min(ys.min() ?? 0, 0), maxY = max(plot.yMax ?? ys.max() ?? 1, minY + 0.0001)

        VStack(spacing: 6) {
            HStack {
                Text((plot.yLabel.map { "\($0) · " } ?? "") + "max \(plain(maxY))")
                Spacer()
            }
            .font(.caption2).foregroundStyle(.secondary)

            Canvas { context, size in
                var axes = Path()
                axes.move(to: .zero)
                axes.addLine(to: CGPoint(x: 0, y: size.height))
                axes.addLine(to: CGPoint(x: size.width, y: size.height))
                context.stroke(axes, with: .color(Color(.systemGray2)), lineWidth: 1.5)
                if minY < 0 {   // show where zero is when the curve dips below it
                    let y = size.height * (1 - (0 - minY) / (maxY - minY))
                    var zero = Path()
                    zero.move(to: CGPoint(x: 0, y: y))
                    zero.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(zero, with: .color(Color(.systemGray3)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                context.clip(to: Path(CGRect(origin: .zero, size: size)))
                for (i, series) in plot.series.enumerated() {
                    var path = Path()
                    for (j, p) in series.points.filter({ $0.count == 2 }).enumerated() {
                        let at = CGPoint(x: size.width * (p[0] - minX) / (maxX - minX),
                                         y: size.height * (1 - (p[1] - minY) / (maxY - minY)))
                        if j == 0 { path.move(to: at) } else { path.addLine(to: at) }
                    }
                    context.stroke(path, with: .color(Self.palette[i % Self.palette.count]),
                                   style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: 150)

            HStack {
                Text(plain(minX))
                Spacer()
                if let x = plot.xLabel { Text(x) }
                Spacer()
                Text(plain(maxX))
            }
            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), alignment: .leading)], alignment: .leading, spacing: 4) {
                ForEach(plot.series.indices, id: \.self) { i in
                    HStack(spacing: 5) {
                        Circle().fill(Self.palette[i % Self.palette.count]).frame(width: 9, height: 9)
                        Text(plot.series[i].label).font(.caption.weight(.medium)).lineLimit(1)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(caption ?? "Plot of " + plot.series.map(\.label).joined(separator: ", "))
    }
}

// MARK: - Timeline, icons, compare

private struct TimelineView: View {
    let timeline: CardVisual.Timeline
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(timeline.events.indices, id: \.self) { i in
                let event = timeline.events[i]
                HStack(alignment: .top, spacing: 10) {
                    Text(event.when)
                        .font(.footnote.bold().monospacedDigit())
                        .foregroundStyle(color)
                        .frame(width: 78, alignment: .trailing)
                    Text(event.what)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 20)
                        .padding(.bottom, i + 1 < timeline.events.count ? 14 : 0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(alignment: .topLeading) {
                            // The dot, and a line down to the next one.
                            ZStack(alignment: .top) {
                                if i + 1 < timeline.events.count {
                                    Rectangle().fill(color.opacity(0.3)).frame(width: 2).padding(.top, 6)
                                }
                                Circle().fill(color).frame(width: 10, height: 10).padding(.top, 4)
                            }
                            .frame(width: 10)
                        }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct IconsView: View {
    let icons: CardVisual.Icons
    let color: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), alignment: .top)], spacing: 12) {
            ForEach(icons.items.indices, id: \.self) { i in
                VStack(spacing: 6) {
                    Image(systemName: icons.items[i].symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(color.gradient, in: .rect(cornerRadius: 14))
                    Text(icons.items[i].label)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct CompareView: View {
    let compare: CardVisual.Compare
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            side(compare.left, tint: color)
            side(compare.right, tint: Color(.systemGray))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func side(_ side: CardVisual.Compare.Side, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(side.title)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
            ForEach(side.points, id: \.self) { point in
                Text(point)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(tint.opacity(0.14), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
