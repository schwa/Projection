import SwiftUI
import CoreGraphicsSupport

struct TeapotView: View {

    @State
    var teapot: TrivialMesh<UInt32, SIMD3<Float>>

    init() {
        teapot = loadTeapot()
    }
    
    var body: some View {
        SoftwareRendererView { projection, context2D, context3D in
            var rasterizer = context3D.rasterizer
            //                for model in models {
            //                    for (index, polygon) in model.toPolygons().enumerated() {
            //                        rasterizer.submit(polygon: polygon.vertices.map { $0.position }, with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
            //                    }
            //                }
            
            for (index, polygon) in teapot.toPolygons().enumerated() {
                rasterizer.submit(polygon: polygon.map { $0 }, with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
            }
            
            rasterizer.rasterize()

        }
    }
}

