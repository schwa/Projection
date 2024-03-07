import CoreGraphicsSupport
import SwiftUI
import GeometryX
import CoreGraphicsSupport

struct BoxesView: View {
    @State
    var models: [any PolygonConvertable]

    init() {
        models = [
            Box(min: [-1, -0.5, -0.5], max: [-2.0, 0.5, 0.5]),
            Sphere(center: .zero, radius: 0.5),
            Box(min: [1, -0.5, -0.5], max: [2.0, 0.5, 0.5]),
        ]
    }

    var body: some View {
        SoftwareRendererView { projection, context2D, context3D in
            var rasterizer = context3D.rasterizer
            for model in models {
                for (index, polygon) in model.toPolygons().enumerated() {
                    rasterizer.submit(polygon: polygon.vertices.map(\.position), with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                }
            }


            print(projection.unproject(CGPoint(projection.size / 2), z: 0))
            print(projection.unproject(CGPoint(projection.size / 2), z: 1000))

            rasterizer.rasterize()
        }
        .toolbar {
            Button("Export") {

            }
        }
    }
}
