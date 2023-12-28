import CoreGraphicsSupport
import Projection
import SwiftUI
import GeometryX

struct MeshView: View {
    static let models = ["Teapot", "Monkey", "Cube", "Square", "Icosphere"]

    @State
    var model: String = "Teapot"

    @State
    var mesh: TrivialMesh<UInt32, SimpleVertex>

    enum Mode {
        case model
        case vertices
    }

    @State
    var mode: Mode = .model


    init() {
        let url = Bundle.main.url(forResource: "Teapot", withExtension: "ply")!
        mesh = try! TrivialMesh(url: url)
    }

    var body: some View {
        ZStack {
            switch mode {
            case .model:
                SoftwareRendererView { _, _, context3D in
                    var rasterizer = context3D.rasterizer
                    for (index, polygon) in mesh.toPolygons().enumerated() {
                        rasterizer.submit(polygon: polygon.map { $0.position }, with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                    }
                    rasterizer.rasterize()
                    context3D.stroke(path: Path3D(box: mesh.boundingBox), with: .color(.purple))
                    for vertex in mesh.vertices {
                        let path = Path3D { path in
                            path.move(to: vertex.position)
                            path.addLine(to: vertex.position + vertex.normal * 0.25)
                        }
                        context3D.stroke(path: path, with: .color(.blue))
                    }
                }
            case .vertices:
                Table(mesh.vertices.indices.map { Identified(id: $0, value: mesh.vertices[Int($0)])}) {
                    TableColumn("Position X") { Text(verbatim: "\($0.value.position.x)") }
                    TableColumn("Position Y") { Text(verbatim: "\($0.value.position.y)") }
                    TableColumn("Position Z") { Text(verbatim: "\($0.value.position.z)") }
                    TableColumn("Normal X") { Text(verbatim: "\($0.value.normal.x)") }
                    TableColumn("Normal Y") { Text(verbatim: "\($0.value.normal.y)") }
                    TableColumn("Normal Z") { Text(verbatim: "\($0.value.normal.z)") }
                    TableColumn("Texture X") { Text(verbatim: "\($0.value.textureCoordinate.x)") }
                    TableColumn("Texture Y") { Text(verbatim: "\($0.value.textureCoordinate.y)") }
                }
            }
        }
        .toolbar {
            Picker("Model", selection: $model) {
                ForEach(Self.models, id: \.self) { model in
                    Text(verbatim: model).tag(model)
                }
            }
            .fixedSize()

            Picker("Mode", selection: $mode) {
                Text(verbatim: "Render").tag(Mode.model)
                Text(verbatim: "Vertices").tag(Mode.vertices)
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .onChange(of: model) {
            let url = Bundle.main.url(forResource: model, withExtension: "ply")!
            mesh = try! TrivialMesh(url: url).renormalize()
        }
    }
}

extension Box where Point == SIMD3<Float> {
    var minXMinYMinZ: SIMD3<Float> { [min.x, min.y, min.z] }
    var minXMinYMaxZ: SIMD3<Float> { [min.x, min.y, max.z] }
    var minXMaxYMinZ: SIMD3<Float> { [min.x, max.y, min.z] }
    var minXMaxYMaxZ: SIMD3<Float> { [min.x, max.y, max.z] }
    var maxXMinYMinZ: SIMD3<Float> { [max.x, min.y, min.z] }
    var maxXMinYMaxZ: SIMD3<Float> { [max.x, min.y, max.z] }
    var maxXMaxYMinZ: SIMD3<Float> { [max.x, max.y, min.z] }
    var maxXMaxYMaxZ: SIMD3<Float> { [max.x, max.y, max.z] }
}

extension Path3D {
    init(box: Box<SIMD3<Float>>) {
        self = Path3D { path in
            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMaxYMinZ)
            path.addLine(to: box.minXMaxYMinZ)
            path.closePath()

            path.move(to: box.minXMinYMaxZ)
            path.addLine(to: box.maxXMinYMaxZ)
            path.addLine(to: box.maxXMaxYMaxZ)
            path.addLine(to: box.minXMaxYMaxZ)
            path.closePath()

            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.minXMinYMaxZ)

            path.move(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMinYMaxZ)

            path.move(to: box.maxXMaxYMinZ)
            path.addLine(to: box.maxXMaxYMaxZ)

            path.move(to: box.minXMaxYMinZ)
            path.addLine(to: box.minXMaxYMaxZ)
        }
    }
}

struct Identified <ID, Value>: Identifiable where ID: Hashable {
    var id: ID
    var value: Value
}
