import simd
import Algorithms

public struct TrivialMesh<Index, Vertex> where Index: UnsignedInteger & BinaryInteger, Vertex: Equatable {
    public var indices: [Index]
    public var vertices: [Vertex]

    public init() {
        indices = []
        vertices = []
    }

    public init(indices: [Index], vertices: [Vertex]) {
        self.indices = indices
        self.vertices = vertices
    }
}

public extension TrivialMesh {
    mutating func append(vertex: Vertex) {
        if let index = vertices.firstIndex(of: vertex) {
            indices.append(Index(index))
        }
        else {
            indices.append(Index(vertices.count))
            vertices.append(vertex)
        }
    }
}

public extension TrivialMesh where Vertex: VertexLike {
    init(quads: [Quad<Vertex>]) {
        let triangles = quads.flatMap { let triangles = $0.subdivide(); return [triangles.0, triangles.1] }
        self.init(triangles: triangles)
    }

    init(triangles: [Triangle<Vertex>]) {
        self.init()
        for triangle in triangles {
            append(vertex: triangle.vertices.0)
            append(vertex: triangle.vertices.1)
            append(vertex: triangle.vertices.2)
        }
    }
}

public extension TrivialMesh {
    init(merging meshes: [TrivialMesh]) {
        self = meshes.reduce(into: TrivialMesh()) { result, mesh in
            let offset = result.vertices.count
            result.indices.append(contentsOf: mesh.indices.map { $0 + Index(offset) })
            result.vertices.append(contentsOf: mesh.vertices)
            // TODO: Does not compact vertices
        }
    }

    func reversed() -> TrivialMesh {
        let indices = indices.chunks(ofCount: 3).flatMap {
            $0.reversed()
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }

    func transformedVertices(_ transform: (Vertex) -> Vertex) -> Self {
        return TrivialMesh(indices: indices, vertices: vertices.map { transform($0) })
    }
}

public extension TrivialMesh where Vertex == SIMD3<Float> {
    func flipped() -> Self {
        let indices = indices.chunks(ofCount: 3).flatMap { $0.reversed() }
        return TrivialMesh(indices: indices, vertices: vertices)
    }

    func offset(by delta: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map { $0 + delta })
    }

    func scale(by scale: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map { $0 * scale })
    }

    // TODO: We can replace this with an extension.
    var boundingBox: Box<SIMD3<Float>> {
        guard let first = vertices.first else {
            return Box(min: .zero, max: .zero)
        }
        let min = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.min(result.x, vertex.x)
            result.y = Swift.min(result.y, vertex.y)
            result.z = Swift.min(result.z, vertex.z)
        }
        let max = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.max(result.x, vertex.x)
            result.y = Swift.max(result.y, vertex.y)
            result.z = Swift.max(result.z, vertex.z)
        }
        return Box(min: min, max: max)
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {

    func flipped() -> Self {
        let indices = indices.chunks(ofCount: 3).flatMap { $0.reversed() }
        let vertices = vertices.map {
            var vertex = $0
            vertex.normal *= -1
            return vertex

        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }


    func offset(by delta: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map {
            SimpleVertex(position: $0.position + delta, normal: $0.normal, textureCoordinate: $0.textureCoordinate)
        })
    }

    func scale(by scale: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map {
            SimpleVertex(position: $0.position * scale, normal: $0.normal, textureCoordinate: $0.textureCoordinate)
        })
    }

    var boundingBox: Box<SIMD3<Float>> {
        guard let first = vertices.first?.position else {
            return Box(min: .zero, max: .zero)
        }
        let min = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.min(result.x, vertex.position.x)
            result.y = Swift.min(result.y, vertex.position.y)
            result.z = Swift.min(result.z, vertex.position.z)
        }
        let max = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.max(result.x, vertex.position.x)
            result.y = Swift.max(result.y, vertex.position.y)
            result.z = Swift.max(result.z, vertex.position.z)
        }
        return Box(min: min, max: max)
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {
    var isValid: Bool {
        // Not a mesh of triangles...
        if indices.count % 3 != 0 {
            return false
        }
        // Index points to a missing vertex
        if indices.contains(where: { Int($0) > vertices.count }) {
            return false
        }
        // Bad vertex
        if vertices.contains(where: {
            $0.position.x.isNaN || $0.position.y.isNaN || $0.position.y.isNaN
            || $0.position.x.isInfinite || $0.position.y.isInfinite || $0.position.y.isInfinite
            || $0.normal.x.isNaN || $0.normal.y.isNaN || $0.normal.y.isNaN
            || $0.normal.x.isInfinite || $0.normal.y.isInfinite || $0.normal.y.isInfinite
        }) {
            return false
        }

        if vertices.contains(where: {
            !$0.normal.isNormalizedish
        }) {
            return false
        }
        return true
    }
}

public extension SIMD3 where Scalar == Float {
    var isNormalizedish: Bool {
        let error = abs(1.0 - simd_length_squared(self))
        return error <= 0.000001
    }
}
