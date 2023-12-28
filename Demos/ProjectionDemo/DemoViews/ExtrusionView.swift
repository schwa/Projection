import Algorithms
import CoreGraphicsSupport
import CoreText
import earcut
import Everything
import SwiftUI
import UniformTypeIdentifiers
import Projection
import ModelIO
import GeometryX

extension UTType {
    static let plyFile = UTType(importedAs: "public.polygon-file-format")
}

struct ExtrusionView: View {

    @State
    var path: Path

    @State
    var mesh: TrivialMesh<UInt, SimpleVertex>

    @State
    var source: String

    @State
    var fileExporterIsPresented = false

    init() {

//         let font = CTFontCreateWithName("Apple Color Emoji" as CFString, 20, nil)
//         let glyph = CTFontGetGlyphWithName(font, "numbersign" as CFString)
//         let cgPath = CTFontCreatePathForGlyph(font, glyph, nil)!
//         let path = Path(cgPath)
//                    for x in 0..<65535 {
//                        let name = CTFontCopyNameForGlyph(font, UInt16(x))
//                        if let name {
//                            print(name)
//                        }
//                    }

        let path = Path.star(points: 12, innerRadius: 0.5, outerRadius: 1)
        let polygons = path.polygonalChains.filter(\.isClosed).map { Polygon(polygonalChain: $0) }
        var mesh = TrivialMesh(merging: polygons.map { $0.extrude(min: 0, max: 3, topCap: true, bottomCap: true) })
        mesh = mesh.offset(by: -mesh.boundingBox.min)
//        mesh = mesh.scale(by: [0.25, 0.25, 0.25])
        self.path = path
        self.mesh = mesh
        self.source = mesh.toPLY()
    }

    var body: some View {
        TabView {
            SoftwareRendererView { _, _, context3D in
                var rasterizer = context3D.rasterizer
                for (index, polygon) in mesh.toPolygons().enumerated() {
                    rasterizer.submit(polygon: polygon.map { $0.position }, with: .color(Color(rgb: kellyColors[index % kellyColors.count])))
                }
                rasterizer.rasterize()
//                context3D.stroke(path: Path3D(path: path), with: .color(.black), lineWidth: 1)
            }
            .tabItem {
                Text("Model")
            }

            TextEditor(text: .constant(source))
                .monospaced()
                .textSelection(.enabled)
            .tabItem {
                Text("Source")
            }
        }
        .toolbar {
            Button("Export") {
                fileExporterIsPresented = true

//                let asset = MDLAsset()
//                let mesh = MDLMesh(trivialMesh: mesh)
            }
        }
        .fileExporter(isPresented: $fileExporterIsPresented, item: source, contentTypes: [.plyFile], onCompletion: { result in
            print(result)
        })
    }
}

extension Path3D {
    init(path: Path) {
        let elements = path.elements
        self = Path3D { path in
            for element in elements {
                switch element {
                case .move(let point):
                    path.move(to: SIMD3(xy: SIMD2(point)))
                case .line(let point):
                    path.addLine(to: SIMD3(xy: SIMD2(point)))
                case .closeSubpath:
                    path.closePath()
                default:
                    fatalError("Unimplemented")
                }
            }
        }
    }
}

extension Path {
    static func star(points: Int, innerRadius: Double, outerRadius: Double) -> Path {
        var path = Path()
        assert(points > 1, "Number of points should be greater than 1 for a star")
        var angle = -0.5 * .pi // Starting from the top
        for n in 0..<points * 2 {
            let radius = n % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if path.isEmpty {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            angle += .pi / Double(points)
        }
        path.closeSubpath()
        return path
    }
}

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    init(xy: SIMD2<Scalar>) {
        self = SIMD3(xy[0], xy[1], 0)
    }
}
