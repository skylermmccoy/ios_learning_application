import Foundation

/// A diagram on a teaching card, described as data in lessons.json and drawn by `CardVisualView`.
/// Types, fields and limits are documented in docs/LESSON_FORMAT.md ("Visuals").
struct CardVisual: Decodable, Hashable {
    let kind: Kind
    /// One line under the diagram saying what to look at.
    let caption: String?

    enum Kind: Hashable {
        case bars(Bars)
        case cells(Cells)
        case flow(Flow)
        case stack(Layers)
        case graph(Graph)
        case tree(Tree)
        case table(Table)
        case plot(Plot)
        case timeline(Timeline)
        case icons(Icons)
        case compare(Compare)
        /// A step-through: the learner taps Next to move from one visual to the next.
        case frames([CardVisual])
    }

    /// An array of numbers as columns.
    struct Bars: Decodable, Hashable {
        let values: [Double]
        let labels: [String]?
        let highlight: [Int]?
        let done: [Int]?
        /// Named markers under a column, e.g. `["lo": 0, "hi": 5]`.
        let pointers: [String: Int]?
    }

    /// A row of boxes holding text.
    struct Cells: Decodable, Hashable {
        let items: [String]
        let highlight: [Int]?
        let done: [Int]?
        let pointers: [String: Int]?
        /// Show 0, 1, 2… under the boxes.
        let indices: Bool?
        /// Draw an arrow between neighbouring boxes (linked list, queue).
        let arrows: Bool?
    }

    /// Steps in order, joined by arrows.
    struct Flow: Decodable, Hashable {
        let steps: [String]
        let highlight: [Int]?
    }

    /// Layers stacked top first, no arrows.
    struct Layers: Decodable, Hashable {
        let layers: [String]
        let highlight: [Int]?
    }

    struct Graph: Decodable, Hashable {
        struct Node: Decodable, Hashable {
            let id: String
            /// 0…1 across and down, (0, 0) is the top left.
            let x: Double
            let y: Double
            let label: String?
        }
        struct Edge: Decodable, Hashable {
            let from: String
            let to: String
            let label: String?
        }
        let nodes: [Node]
        let edges: [Edge]?
        let directed: Bool?
        /// Node ids.
        let highlight: [String]?
        /// Pairs of node ids.
        let highlightEdges: [[String]]?
    }

    /// A tree, laid out automatically.
    struct Tree: Decodable, Hashable {
        struct Node: Decodable, Hashable {
            let label: String
            /// A nil child keeps an empty slot, so a lone right child stays on the right.
            let children: [Node?]?
        }
        let root: Node
        /// Labels of the nodes to highlight.
        let highlight: [String]?
    }

    struct Table: Decodable, Hashable {
        let headers: [String]?
        let rows: [[String]]
        /// `[row, column]` pairs.
        let highlight: [[Int]]?
        let highlightRows: [Int]?
    }

    /// Lines on a pair of axes.
    struct Plot: Decodable, Hashable {
        struct Series: Decodable, Hashable {
            let label: String
            /// `[x, y]` pairs.
            let points: [[Double]]
        }
        let series: [Series]
        let xLabel: String?
        let yLabel: String?
        /// Clip the vertical axis here so one steep curve doesn't flatten the rest.
        let yMax: Double?
    }

    struct Timeline: Decodable, Hashable {
        struct Event: Decodable, Hashable {
            let when: String
            let what: String
        }
        let events: [Event]
    }

    /// A few named ideas, each with an SF Symbol.
    struct Icons: Decodable, Hashable {
        struct Item: Decodable, Hashable {
            let symbol: String
            let label: String
        }
        let items: [Item]
    }

    struct Compare: Decodable, Hashable {
        struct Side: Decodable, Hashable {
            let title: String
            let points: [String]
        }
        let left: Side
        let right: Side
    }

    private enum CodingKeys: String, CodingKey { case type, caption, frames }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "bars": kind = .bars(try Bars(from: decoder))
        case "cells": kind = .cells(try Cells(from: decoder))
        case "flow": kind = .flow(try Flow(from: decoder))
        case "stack": kind = .stack(try Layers(from: decoder))
        case "graph": kind = .graph(try Graph(from: decoder))
        case "tree": kind = .tree(try Tree(from: decoder))
        case "table": kind = .table(try Table(from: decoder))
        case "plot": kind = .plot(try Plot(from: decoder))
        case "timeline": kind = .timeline(try Timeline(from: decoder))
        case "icons": kind = .icons(try Icons(from: decoder))
        case "compare": kind = .compare(try Compare(from: decoder))
        case "frames": kind = .frames(try container.decode([CardVisual].self, forKey: .frames))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container,
                                                   debugDescription: "Unknown visual type \(type)")
        }
    }

    /// Every visual in this one, including the frames of a step-through.
    var flattened: [CardVisual] {
        if case .frames(let frames) = kind { return [self] + frames.flatMap(\.flattened) }
        return [self]
    }
}
