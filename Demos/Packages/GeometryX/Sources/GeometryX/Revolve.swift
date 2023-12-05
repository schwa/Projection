import Foundation
import SwiftUI
import simd

public func revolve(polygonalChain: PolygonalChain<SIMD3<Float>>, axis: Line<SIMD3<Float>>, range: Range<Angle>, detail: Int) -> TrivialMesh<UInt, SimpleVertex> {
    fatalError()
}

public func revolve(lineSegment: LineSegment<SIMD3<Float>>, axis: Line<SIMD3<Float>>, range: Range<Angle>) -> Quad<SIMD3<Float>> {
    fatalError()
}

public func revolve(point: SIMD3<Float>, axis: Line<SIMD3<Float>>, range: Range<Angle>) -> LineSegment<SIMD3<Float>> {
    let center = axis.closest(to: point)
    fatalError()
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
