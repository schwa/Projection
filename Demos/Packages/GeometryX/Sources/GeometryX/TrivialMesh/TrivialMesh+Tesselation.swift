import earcut
import simd
import CoreGraphics

public extension TrivialMesh where Vertex == SIMD3<Float> {
    init(polygon: [CGPoint], z: Float) {
        let vertices = polygon.map { SIMD3<Float>(Float($0.x), Float($0.y), z) }
        let indices = earcut(polygons: [vertices.map { $0.xy }]).map({ Int($0) })
        self = .init(indices: indices, vertices: vertices)
    }
}
