import SwiftUI

extension Path {
    var elements: [Path.Element] {
        var elements: [Path.Element] = []
        forEach { element in
            elements.append(element)
        }
        return elements
    }

    var polygonalChains: [PolygonalChain<CGPoint>] {
        var polygons: [[CGPoint]] = []
        var current: [CGPoint] = []
        var lastPoint: CGPoint?
        for element in elements {
            switch element {
            case .move(let point):
                current.append(point)
                lastPoint = point
            case .line(let point):
                if current.isEmpty {
                    current = [lastPoint ?? .zero]
                }
                current.append(point)
                lastPoint = point
            case .quadCurve:
                fatalError()
            case .curve:
                fatalError()
            case .closeSubpath:
                if let first = current.first {
                    current.append(first)
                    polygons.append(current)
                }
                current = []
            }
        }
        if !current.isEmpty {
            polygons.append(current)
        }
        return polygons.map { .init(vertices: $0) }
    }

    init(lines points: [CGPoint]) {
        self = Path { path in
            path.addLines(points)
        }
    }
}

extension Path {
    func render(transform: CGAffineTransform = .identity) -> [LineSegment<CGPoint>] {
        var segments: [LineSegment<CGPoint>] = []
        var subpathStart: CGPoint?
        var currentPoint: CGPoint = .zero
        forEach { element in
            switch element {
            case .move(to: let to):
                currentPoint = to
            case .line(to: let to):
                if subpathStart == nil {
                    subpathStart = currentPoint
                }
                segments.append(LineSegment(start: currentPoint.applying(transform), end: to.applying(transform)))
                currentPoint = to
            case .quadCurve:
                fatalError("Got a quadCurve i can't handle")
            case .curve:
                fatalError("Got a curve i can't handle")
            case .closeSubpath:
                if let subpathStart {
                    segments.append(LineSegment(start: currentPoint.applying(transform), end: subpathStart.applying(transform)))
                }
                subpathStart = nil
            }
        }
        return segments
    }
}
