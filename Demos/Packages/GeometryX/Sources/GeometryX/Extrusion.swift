import Algorithms
import earcut
import CoreGraphics
import simd

// swiftlint:disable force_unwrapping

public enum ExtrusionAxis {
    case x
    case y
    case z
}

public extension ExtrusionAxis {
    var transform: simd_float3x3 {
        switch self {
        case .x:
            simd_float3x3([0, 0, 1], [0, 1, 0], [1, 0, 0])
        case .y:
            simd_float3x3([1, 0, 0], [0, 0, 1], [0, 1, 0])
        case .z:
            simd_float3x3([1, 0, 0], [0, 1, 0], [0, 0, 1])
        }
    }
}

public extension PolygonalChain where Point == CGPoint {
    func extrude(min: Float, max: Float, axis: ExtrusionAxis = .z) -> TrivialMesh<UInt, SimpleVertex> {
        let quads: [Quad<SimpleVertex>] = vertices.windows(ofCount: 2).reduce(into: []) { result, window in
            let from = SIMD2<Float>(x: Float(window.first!.x), y: Float(window.first!.y))
            let to = SIMD2<Float>(x: Float(window.last!.x), y: Float(window.last!.y))
            let transform = axis.transform
            let normal = SIMD3<Float>(0, 0, 1) * transform
            let quad = Quad(vertices: (
                SimpleVertex(position: SIMD3<Float>(from.x, from.y, min) * transform, normal: normal, textureCoordinate: [0, 0]),
                SimpleVertex(position: SIMD3<Float>(from.x, from.y, max) * transform, normal: normal, textureCoordinate: [0, 1]),
                SimpleVertex(position: SIMD3<Float>(to.x, to.y, min) * transform, normal: normal, textureCoordinate: [1, 0]),
                SimpleVertex(position: SIMD3<Float>(to.x, to.y, max) * transform, normal: normal, textureCoordinate: [1, 1])
            ))
            result.append(quad)
        }
        let mesh = TrivialMesh<UInt, SimpleVertex>(quads: quads).reversed() // TODO: Silly. Just reverse the quad
        return mesh
    }
}

public extension Polygon where Vertex == CGPoint {
    func extrude(min: Float, max: Float, axis: ExtrusionAxis = .z, walls: Bool = true, topCap: Bool, bottomCap: Bool) -> TrivialMesh<UInt, SimpleVertex> {
        let walls = walls ? PolygonalChain(polygon: self).extrude(min: min, max: max, axis: axis) : nil
        let topCap = topCap ? triangulate(z: max, transform: axis.transform) : nil
        let bottomCap = bottomCap ? triangulate(z: min, transform: axis.transform).flipped() : nil
        return TrivialMesh(merging: Array([walls, topCap, bottomCap].compacted()))
    }

    func triangulate(z: Float = 0, transform: simd_float3x3 = .init(diagonal: [1, 1, 1])) -> TrivialMesh<UInt, SimpleVertex> {
        let indices = earcut(polygons: [vertices.map({ SIMD2($0) })]).map({ UInt($0) })
        assert(!indices.isEmpty)
        let vertices = vertices.map {
            // TODO: We're not calculating texture coordinate here.
            return SimpleVertex(position: [Float($0.x), Float($0.y), z] * transform, normal: [0, 0, 1] * transform, textureCoordinate: [0, 0])
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }
}

public extension SIMD2 where Scalar == Float {
    init(_ point: CGPoint) {
        self = [Float(point.x), Float(point.y)]
    }
}
