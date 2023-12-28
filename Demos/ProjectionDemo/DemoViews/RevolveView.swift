import SwiftUI
import GeometryX
import CoreGraphicsSupport
import Projection

struct RevolveView: View {

    let polygonalChain: PolygonalChain<SIMD3<Float>>
    let axis: Line<SIMD3<Float>>
    let mesh: TrivialMesh<UInt, SIMD3<Float>>

    init() {
        polygonalChain = .init(vertices: [
            [0, 0, 0],
            [-1, 0, 0],
            [-1, 2.5, 0],
            [0, 2.5, 0],
        ])
        axis = Line<SIMD3<Float>>(point: [0, 0, 0], direction: [0, 1, 0])
        mesh = revolve(polygonalChain: polygonalChain, axis: axis, range: .degrees(0) ... .degrees(360), segments: 4)
    }

    var body: some View {
        SoftwareRendererView { _, _, context3D in
//            context3D.stroke(path: Path3D(polygonalChain), with: .color(.purple), lineWidth: 2)
            var rasterizer = context3D.rasterizer
            for (index, polygon) in mesh.toPolygons().enumerated() {
                rasterizer.submit(polygon: polygon.map { $0 }, with: .color(Color(rgb: kellyColors[index % kellyColors.count])))
            }
            rasterizer.rasterize()
        }
    }
}

extension Path3D {
    init(_ polygonalChain: PolygonalChain<SIMD3<Float>>) {
        self = Path3D { path in
            let vertices = polygonalChain.vertices
            if let first = vertices.first {
                path.move(to: first)
                for vertex in vertices.dropFirst() {
                    path.addLine(to: vertex)
                }
            }

        }
    }

}
