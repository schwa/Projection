import CoreGraphicsSupport
import Algorithms
import earcut
import UniformTypeIdentifiers

extension PolygonalChain where Point == CGPoint {
    func extrude(min: Float, max: Float) -> TrivialMesh<UInt, SIMD3<Float>> {
        let quads: [Quad<SIMD3<Float>>] = vertices.windows(ofCount: 2).reduce(into: []) { result, window in
            let from = SIMD2<Float>(window.first!)
            let to = SIMD2<Float>(window.last!)
            let quad = Quad(vertices: (
                // TODO: Invent way to control which axis is extruded
                SIMD3<Float>(from, min),
                SIMD3<Float>(from, max),
                SIMD3<Float>(to, min),
                SIMD3<Float>(to, max)
            ))
            result.append(quad)
        }
        let mesh = TrivialMesh<UInt,SIMD3<Float>>(quads: quads)
        return mesh
    }
}

extension Polygon where Vertex == CGPoint {
    func extrude(min: Float, max: Float, topCap: Bool, bottomCap: Bool) -> TrivialMesh<UInt, SIMD3<Float>> {
        let walls = PolygonalChain(polygon: self).extrude(min: min, max: max)
        let topCap = topCap ? triangulate(z: max) : nil
        let bottomCap = bottomCap ? triangulate(z: min).flipped() : nil
        return TrivialMesh(merging: Array([walls, topCap, bottomCap].compacted()))
    }

    func triangulate(z: Float = 0) -> TrivialMesh<UInt, SIMD3<Float>> {
        let vertices = vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), z) }
        let indices = earcut(polygons: [vertices.map { $0.xy }]).map({ UInt($0) })
        return TrivialMesh(indices: indices, vertices: vertices)
    }
}
