import SIMDSupport

protocol PolygonConvertable {
    func toPolygons() -> [Polygon<SimpleVertex>]
}

protocol MeshConvertable {
    func toMesh() -> TrivialMesh<UInt, SIMD3<Float>>
}
//
//public extension PolygonConvertable {
//    func toCSG() -> CSG<SimpleVertex> {
//        return CSG(polygons: toPolygons())
//    }
//}

extension Box: PolygonConvertable where Point == SIMD3<Float> {
    func toPolygons() -> [Polygon<SimpleVertex>] {
        let polygons = [
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
            ]).flipped(),

            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
            ]).flipped(),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
            ]),
        ]
        return polygons
    }
}

extension Sphere: PolygonConvertable {
    public func toPolygons() -> [Polygon<SimpleVertex>] {
        let slices = 12
        let stacks = 12
        var polygons: [Polygon<SimpleVertex>] = []
        func vertex(_ theta: Angle<Float>, _ phi: Angle<Float>) -> SimpleVertex {
            let dir = SIMD3<Float>(cos(theta.radians) * sin(phi.radians), cos(phi.radians), sin(theta.radians) * sin(phi.radians))
            return SimpleVertex(position: dir * radius + center, normal: dir)
        }
        for i in 0 ..< slices {
            for j in 0 ..< stacks {
                let v1 = vertex(.degrees(Float(i) / Float(slices) * 360), .degrees(Float(j) / Float(stacks) * 180))
                let v2 = vertex(.degrees(Float(i + 1) / Float(slices) * 360), .degrees(Float(j) / Float(stacks) * 180))
                let v3 = vertex(.degrees(Float(i + 1) / Float(slices) * 360), .degrees(Float(j + 1) / Float(stacks) * 180))
                let v4 = vertex(.degrees(Float(i) / Float(slices) * 360), .degrees(Float(j + 1) / Float(stacks) * 180))
                polygons.append(Polygon(vertices: [v1, v2, v3]))
                polygons.append(Polygon(vertices: [v1, v3, v4]))
            }
        }
        return polygons
    }
}

//public extension CSG {
//    func toPLY() -> String {
//        let vertices = polygons.flatMap { $0.vertices }
//        let faces: [[Int]] = polygons.reduce(into: []) { partialResult, polygon in
//            let nextIndex = partialResult.map { $0.count }.reduce(0, +)
//            partialResult.append(Array(nextIndex ..< nextIndex + polygon.vertices.count))
//        }
//        var s = ""
//        let encoder = PlyEncoder()
//        encoder.encodeHeader(to: &s)
//        encoder.encodeVersion(to: &s)
//        encoder.encodeElementDefinition(name: "vertex", count: vertices.count, properties: [
//            (.float, "x"), (.float, "y"), (.float, "z"),
//            (.float, "nx"), (.float, "ny"), (.float, "nz"),
//            (.uchar, "red"), (.uchar, "green"), (.uchar, "blue"),
//        ], to: &s)
//        encoder.encodeElementDefinition(name: "face", count: faces.count, properties: [
//            (.list(count: .uchar, element: .int), "vertex_indices")
//        ], to: &s)
//        encoder.encodeEndHeader(to: &s)
//
//        for vertex in vertices {
//            encoder.encodeElement([
//                .float(vertex.position.x), .float(vertex.position.y), .float(vertex.position.z),
//                .float(vertex.normal.x), .float(vertex.normal.y), .float(vertex.normal.z),
//                .uchar(128), .uchar(128), .uchar(128)
//            ], to: &s)
//        }
//        for face in faces {
//            let indices = face.map { PlyEncoder.Value.int(Int32($0)) }
//            encoder.encodeListElement(indices, to: &s)
//        }
//
//        return s
//    }
//}
