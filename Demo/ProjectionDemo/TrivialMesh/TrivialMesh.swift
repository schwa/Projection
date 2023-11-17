import simd

struct TrivialMesh <Index, Vertex> where Index: UnsignedInteger & BinaryInteger, Vertex: Equatable {
    var indices: [Index]
    var vertices: [Vertex]
    
    init() {
        self.indices = []
        self.vertices = []
    }
    
    init(indices: [Index], vertices: [Vertex]) {
        self.indices = indices
        self.vertices = vertices
    }
}

extension TrivialMesh {
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

extension TrivialMesh where Vertex == SIMD3<Float> {
    init(quads: [Quad<SIMD3<Float>>]) {
        let triangles = quads.flatMap { let triangles = $0.subdivide(); return [triangles.0.reversed, triangles.1.reversed] }
        self.init(triangles: triangles)
    }

    init(triangles: [Triangle<SIMD3<Float>>]) {
        self.init()
        for triangle in triangles {
            self.append(vertex: triangle.vertices.0)
            self.append(vertex: triangle.vertices.1)
            self.append(vertex: triangle.vertices.2)
        }
    }
}

extension TrivialMesh {
    static func merging(meshes: [TrivialMesh]) -> TrivialMesh {
        meshes.reduce(into: TrivialMesh()) { result, mesh in
            let offset = result.vertices.count
            result.indices.append(contentsOf: mesh.indices.map { $0 + Index(offset) })
            result.vertices.append(contentsOf: mesh.vertices)
        }
    }
    
    func reversed() -> TrivialMesh {
        let indices = indices.chunks(ofCount: 3).flatMap {
            $0.reversed()
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }
}

extension TrivialMesh where Vertex == SIMD3<Float> {
    func offset(by delta: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map { $0 + delta })
    }
    
    var boundingBox: (min: SIMD3<Float>, max: SIMD3<Float>) {
        guard let first = vertices.first else {
            return (.zero, .zero)
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
        return (min: min, max: max)
    }
}

