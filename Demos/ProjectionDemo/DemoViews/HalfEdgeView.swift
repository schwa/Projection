import SwiftUI
import GeometryX
import Projection

struct HalfEdgeView: View {

    var mesh: HalfEdgeMesh = .demo()



    var body: some View {
        SoftwareRendererView { _, _, context3D in
            var rasterizer = context3D.rasterizer

            for polygon in mesh.polygons {
                rasterizer.submit(polygon: polygon.vertices, with: .color(.green))
            }
            rasterizer.rasterize()
        }
        .onSpatialTap { location in
            print(location)
        }
    }
}

extension View {
    func onSpatialTap(count: Int = 1, coordinateSpace: some CoordinateSpaceProtocol = .local, handler: @escaping (CGPoint) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded({ value in
            handler(value.location)
        }))
    }
}


extension HalfEdgeMesh {
    static func demo() -> HalfEdgeMesh {

        var mesh = HalfEdgeMesh()
        mesh.addFace(positions: [
            [0, 0, 0],
            [0, 1, 0],
            [1, 1, 0],
            [1, 0, 0],
        ])

        return mesh
    }

    var polygons: [GeometryX.Polygon<SIMD3<Float>>] {
        return faces.map { face in
            var vertices: [SIMD3<Float>] = []
            var halfEdge: HalfEdge! = face.halfEdge
            repeat {
                vertices.append(halfEdge.vertex.position)
                halfEdge = halfEdge.next
            }
            while halfEdge !== face.halfEdge
            return .init(vertices: vertices)
        }
    }
}
