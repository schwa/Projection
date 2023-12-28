import Foundation
import SwiftUI
import RealityKit
import ModelIO

public extension TrivialMesh where Index == UInt32, Vertex == SimpleVertex {
    init(cylinder: Cylinder, segments: Int) {
        let halfDepth = cylinder.depth / 2
        let circle = TrivialMesh(circleRadius: cylinder.radius, segments: segments)
        let top = circle.offset(by: [0, 0, halfDepth])
        let bottom = circle.flipped().offset(by: [0, 0, -halfDepth])

        func makeEdge() -> Self {
            let segmentAngle = Float.pi * 2 / Float(segments)
            let quads = (0..<segments).map { index in
                let startAngle = segmentAngle * Float(index)
                let endAngle = segmentAngle * Float(index + 1)
                let p1 = SIMD3(cos(startAngle) * cylinder.radius, sin(startAngle) * cylinder.radius, 0)
                let p2 = SIMD3(cos(endAngle) * cylinder.radius, sin(endAngle) * cylinder.radius, 0)
                let vertices = [
                    p1 + SIMD3<Float>(0, 0, -halfDepth),
                    p2 + SIMD3<Float>(0, 0, -halfDepth),
                    p1 + SIMD3<Float>(0, 0, halfDepth),
                    p2 + SIMD3<Float>(0, 0, halfDepth)
                ]
                .map {
                    SimpleVertex(position: $0, normal: simd_normalize($0), textureCoordinate: [0, 0])
                }
                return Quad(vertices: vertices)
            }
            return .init(quads: quads)
        }
        self = TrivialMesh(merging: [top, bottom, makeEdge()])
        assert(self.isValid)
        try! self.write(to: URL(filePath: "/tmp/test.obj"))
        try! self.write(to: URL(filePath: "/tmp/test.ply"))
    }

    init(circleRadius radius: Float, segments: Int) {
        let segmentAngle = Float.pi * 2 / Float(segments)
        let vertices2D = [
            SIMD2<Float>(0, 0)
        ] + (0..<(segments)).map {
            SIMD2<Float>(cos(segmentAngle * Float($0)), sin(segmentAngle * Float($0))) * radius
        }
        let vertices = vertices2D.map {
            return SimpleVertex(position: [$0.x, $0.y, 0], normal: [0, 0, 1], textureCoordinate: $0)
        }
        let indices: [UInt32] = (0..<UInt32(segments)).flatMap {
            let p1 = 1 + $0
            let p2 = 1 + ($0 + 1) % UInt32(segments)
            return [0, p1, p2]
        }
        self = .init(indices: indices, vertices: vertices)
        assert(self.isValid)
//        try! self.write(to: URL(filePath: "/tmp/test.obj"))
    }
}

extension TrivialMesh where Vertex == SimpleVertex {
    func write(to url: URL) throws {
        let asset = MDLAsset()
        let mesh = MDLMesh(trivialMesh: self)
        asset.add(mesh)
        try asset.export(to: url)
    }
}

#if os(visionOS)
public struct MeshView: View {
    let mesh: TrivialMesh <UInt32, SimpleVertex>

    public init(mesh: TrivialMesh<UInt32, SimpleVertex>) {
        self.mesh = mesh
    }

    public var body: some View {
        RealityView { content in
            let entity = try! ModelEntity(trivialMesh: mesh)
            entity.orientation = .init(angle: .pi / 2, axis: [1, 0, 0])
            print(entity.visualBounds(relativeTo: nil))
            content.add(entity)
        }
    }
}

#Preview {
    MeshView(mesh: TrivialMesh(cylinder: Cylinder(radius: 0.1, depth: 0.01), segments: 24))
    //MeshView(mesh: TrivialMesh(circleRadius: 1, segments: 24))
}
#endif
