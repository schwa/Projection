import Foundation
import simd
import SIMDSupport

extension Angle: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(radians: Value(value))
    }
}

extension Angle: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .init(radians: Value(value))
    }
}


extension Angle: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians + rhs.radians)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians - rhs.radians)
    }
}


extension Angle: SignedNumeric {
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.radians *= rhs.radians
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        self = .init(radians: Value(source))
    }

    public var magnitude: Self {
        .init(radians: radians.magnitude)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians * rhs.radians)
    }

}

extension Angle: Strideable {
    public typealias Stride = Self

    public func distance(to other: Self) -> Self {
        Self(radians: radians - other.radians)
    }
    public func advanced(by n: Self) -> Self {
        .init(radians: radians + n.radians)
    }
}

public func revolve(polygonalChain: PolygonalChain<SIMD3<Float>>, axis: Line<SIMD3<Float>>, range: ClosedRange<Angle<Float>>) -> TrivialMesh<UInt, SIMD3<Float>> {
    let quads = polygonalChain.segments.map {
        revolve(lineSegment: $0, axis: axis, range: range)
    }
    return TrivialMesh(quads: quads)
}

public func revolve(polygonalChain: PolygonalChain<SIMD3<Float>>, axis: Line<SIMD3<Float>>, range: ClosedRange<Angle<Float>>, segments: Int) -> TrivialMesh<UInt, SIMD3<Float>> {
    let by = Angle<Float>(radians: (range.upperBound.radians - range.lowerBound.radians) / Float(segments))
    let quads = stride(from: range.lowerBound, through: range.upperBound, by: by).flatMap { start in
        let range = start ... start + by
        let quads = polygonalChain.segments.map {
            revolve(lineSegment: $0, axis: axis, range: range)
        }
        return quads
    }
    return TrivialMesh(quads: quads)
}

public func revolve(lineSegment: LineSegment<SIMD3<Float>>, axis: Line<SIMD3<Float>>, range: ClosedRange<Angle<Float>>) -> Quad<SIMD3<Float>> {
    let p1 = revolve(point: lineSegment.start, axis: axis, range: range)
    let p2 = revolve(point: lineSegment.end, axis: axis, range: range)
    return .init(vertices: (p1.start, p1.end, p2.end, p2.start))
}

public func revolve(point: SIMD3<Float>, axis: Line<SIMD3<Float>>, range: ClosedRange<Angle<Float>>) -> LineSegment<SIMD3<Float>> {
    let center = axis.closest(to: point)
    let p1 = simd_quatf(angle: range.lowerBound, axis: axis.direction).act(point - center) + center
    let p2 = simd_quatf(angle: range.upperBound, axis: axis.direction).act(point - center) + center
    return .init(start: p1, end: p2)
}

public extension Line where Point == SIMD3<Float> {
    func closest(to 𝑝0: Point) -> Point {
        // from: https://math.stackexchange.com/a/3223089
        let 𝑙0 = point
        let 𝑙 = direction
        let 𝑡𝑐𝑙𝑜𝑠𝑒𝑠𝑡 = simd.dot(𝑝0 - 𝑙0, 𝑙) / simd.dot(𝑙, 𝑙)
        let 𝑥𝑐𝑙𝑜𝑠𝑒𝑠𝑡 = 𝑙0 + 𝑡𝑐𝑙𝑜𝑠𝑒𝑠𝑡 * 𝑙
        return 𝑥𝑐𝑙𝑜𝑠𝑒𝑠𝑡
    }

    func intersects(plane: Plane<Float>) -> Point {
        fatalError()
    }
}
