import SwiftUI
import SIMDSupport
import Projection
import ModelIO
import Algorithms
import CoreGraphicsSupport
import SwiftFormats

struct SoftwareRendererView: View {
    @State
    var camera: Camera

    @State
    var modelTransform: Transform

    @State
    var ballConstraint: BallConstraint

    @State
    var pitchLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    var yawLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    var rasterizerOptions: Rasterizer.Options = .default

    var renderer: (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void

    init(renderer: @escaping (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1000.0)))
        modelTransform = .init(rotation: .init(angle: .degrees(0), axis: [0, 1, 0]))
        ballConstraint = BallConstraint()
        self.renderer = renderer
    }

    var body: some View {
        Canvas { context, size in
            var projection = Projection3D(size: size)
            projection.viewTransform = camera.transform.matrix.inverse
            projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
            projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])

            context.draw3DLayer(projection: projection) { context, context3D in
                context3D.stroke(path: Path3D { path in
                    path.move(to: [-5, 0, 0])
                    path.addLine(to: [5, 0, 0])
                }, with: .color(.red))
                context3D.stroke(path: Path3D { path in
                    path.move(to: [0, -5, 0])
                    path.addLine(to: [0, 5, 0])
                }, with: .color(.green))
                context3D.stroke(path: Path3D { path in
                    path.move(to: [0, 0, -5])
                    path.addLine(to: [0, 0, 5])
                }, with: .color(.blue))

                if let symbol = context.resolveSymbol(id: "-X") {
                    context.draw(symbol, at: projection.project([-5, 0, 0]))
                }
                if let symbol = context.resolveSymbol(id: "+X") {
                    context.draw(symbol, at: projection.project([5, 0, 0]))
                }
                if let symbol = context.resolveSymbol(id: "-Y") {
                    context.draw(symbol, at: projection.project([0, -5, 0]))
                }
                if let symbol = context.resolveSymbol(id: "+Y") {
                    context.draw(symbol, at: projection.project([0, 5, 0]))
                }
                if let symbol = context.resolveSymbol(id: "-Z") {
                    context.draw(symbol, at: projection.project([0, 0, -5]))
                }
                if let symbol = context.resolveSymbol(id: "+Z") {
                    context.draw(symbol, at: projection.project([0, 0, 5]))
                }
            }
            context.draw3DLayer(projection: projection) { context, context3D in
                context3D.rasterizerOptions = rasterizerOptions
                renderer(projection, &context, &context3D)
            }
        }
        symbols: {
            ForEach(["-X", "+X", "-Y", "+Y", "-Z", "+Z"], id: \.self) { value in
                Text(value).tag(value).font(.caption).background(.white.opacity(0.5))
            }
        }
        .ballRotation($ballConstraint.rotation, pitchLimit: pitchLimit, yawLimit: yawLimit)
        .onAppear() {
            camera.transform.matrix = ballConstraint.transform
        }
        .onChange(of: ballConstraint.transform) {
            camera.transform.matrix = ballConstraint.transform
        }
        .inspector(isPresented: .constant(true)) {
            Form {
                LabeledContent("Map") {
                    MapInspector(camera: $camera, models: []).aspectRatio(1, contentMode: .fill)
                }
                LabeledContent("Rasterizer") {
                    Toggle("Draw Normals", isOn: $rasterizerOptions.drawNormals)
                    Toggle("Shade Normals", isOn: $rasterizerOptions.shadeFragmentsWithNormals)
                    Toggle("Fill", isOn: $rasterizerOptions.fill)
                    Toggle("Stroke", isOn: $rasterizerOptions.stroke)
                }
                LabeledContent("Track Ball") {
                    TextField("Pitch Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                    TextField("Yaw Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                }
                LabeledContent("Camera") {
                    CameraInspector(camera: $camera)
                }
                LabeledContent("Model Transform") {
                    TransformEditor(transform: $modelTransform)
                }
                LabeledContent("Ball Constraint") {
                    BallConstraintEditor(ballConstraint: $ballConstraint)
                }
            }
            .controlSize(.mini)
        }
    }
}

struct BallConstraint {
    var radius: Float = -5
    var lookAt: SIMD3<Float> = .zero
    var rotation: Rotation = .zero

    var transform: simd_float4x4 {
        return rotation.matrix * simd_float4x4(translate: [0, 0, radius])
    }
}

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        TextField("Pitch", value: $ballConstraint.rotation.pitch, format: .angle)
        TextField("Yaw", value: $ballConstraint.rotation.yaw, format: .angle)
    }
}

//            for angle in stride(from: Float.zero, to: 360.0, by: 45.0) {
//                let angle = Angle<Float>(degrees: angle)
//                context.stroke(path: Path3D { path in
//                    path.move(to: [0, 0, 0])
//                    path.line(to: [0, cos(angle.radians) * 5, sin(angle.radians) * 5])
//                }, with: .color(.red))
//                context.stroke(path: Path3D { path in
//                    path.move(to: [0, 0, 0])
//                    path.line(to: [cos(angle.radians) * 5, 0, sin(angle.radians) * 5])
//                }, with: .color(.green))
//                context.stroke(path: Path3D { path in
//                    path.move(to: [0, 0, 0])
//                    path.line(to: [cos(angle.radians) * 5, sin(angle.radians) * 5, 0])
//                }, with: .color(.blue))
//            }

func loadTeapot() -> TrivialMesh <UInt32, SIMD3<Float>> {
    let url = Bundle.main.url(forResource: "Teapot", withExtension: "ply")!
    let asset = MDLAsset(url: url)
    let mesh = asset.object(at: 0) as! MDLMesh

    guard let attribute = mesh.vertexDescriptor.attributes.compactMap({ $0 as? MDLVertexAttribute }).first(where: { $0.name == MDLVertexAttributePosition }) else {
        fatalError()
    }

    let layout = mesh.vertexDescriptor.layouts[attribute.bufferIndex] as! MDLVertexBufferLayout
    let positionBuffer = mesh.vertexBuffers[attribute.bufferIndex]
    let positionBytes = UnsafeRawBufferPointer(start: positionBuffer.map().bytes, count: positionBuffer.length)
    let positions = positionBytes.chunks(ofCount: layout.stride).map { slice in
        let start = slice.index(slice.startIndex, offsetBy: attribute.offset)
        let end = slice.index(start, offsetBy: 12) // TODO: assumes packed float 3
        let slice = slice[start ..< end]
        return slice.load(as: PackedFloat3.self) // TODO: assumes packed float 3
    }

    let submesh = mesh.submeshes![0] as! MDLSubmesh
    let indexBuffer = submesh.indexBuffer
    let indexBytes = UnsafeRawBufferPointer(start: indexBuffer.map().bytes, count: indexBuffer.length)
    let indices = indexBytes.bindMemory(to: UInt32.self)

    return TrivialMesh(indices: Array(indices), vertices: Array(positions.map { SIMD3<Float>($0) }))
}

extension TrivialMesh {
    func toPolygons() -> [[Vertex]] {
        indices.chunks(ofCount: 3).map {
            $0.map { vertices[Int($0)] }
        }
    }
}
