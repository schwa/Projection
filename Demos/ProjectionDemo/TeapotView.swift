import SwiftUI
import CoreGraphicsSupport

struct TeapotView: View {

    static let models = ["Teapot", "Monkey"]

    @State
    var model: String = "Teapot"

    @State
    var mesh: TrivialMesh<UInt32, SIMD3<Float>>

    init() {
        let url = Bundle.main.url(forResource: "Teapot", withExtension: "ply")!
        mesh = try! TrivialMesh(url: url)
    }

    var body: some View {
        SoftwareRendererView { projection, context2D, context3D in
            var rasterizer = context3D.rasterizer
            for (index, polygon) in mesh.toPolygons().enumerated() {
                rasterizer.submit(polygon: polygon.map { $0 }, with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
            }
            rasterizer.rasterize()
        }
        .overlay(alignment: .topLeading) {
            Picker("Model", selection: $model) {
                ForEach(Self.models, id: \.self) { model in
                    Text(verbatim: model).tag(model)
                }
            }
            .fixedSize()
            .padding()
        }
        .onChange(of: model) {
            let url = Bundle.main.url(forResource: model, withExtension: "ply")!
            mesh = try! TrivialMesh(url: url)
        }
    }
}
