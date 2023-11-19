import Algorithms
import CoreGraphicsSupport
import CoreText
import earcut
import Everything
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let plyFile = UTType(importedAs: "public.polygon-file-format")
}

struct ExtrusionView: View {
    @State
    var meshes: [TrivialMesh<UInt, SIMD3<Float>>]

    @State
    var source: String

    @State
    var fileExporterIsPresented = false

    init() {
        let path = Path(CGSize(1, 1))
        let polygons = path.polygonalChains.filter(\.isClosed).map { Polygon(polygonalChain: $0) }
        let meshes = polygons.map { $0.extrude(min: 0, max: 3, topCap: true, bottomCap: true) }
        self.meshes = meshes
        source = TrivialMesh(merging: meshes).toPLY()
    }

    var body: some View {
        TabView {
            SoftwareRendererView { _, _, context3D in
                for mesh in meshes {
                    var rasterizer = context3D.rasterizer
                    for (index, polygon) in mesh.toPolygons().enumerated() {
                        rasterizer.submit(polygon: polygon.map { $0 }, with: .color(Color(rgb: kellyColors[index % kellyColors.count])))
                    }
                    rasterizer.rasterize()
                }
            }
            .tabItem {
                Text("Model")
            }

            Text(verbatim: source)
                .monospaced()
                .textSelection(.enabled)
                .tabItem {
                    Text("PLY")
                }
        }
        .toolbar {
            Button("Export") {
                fileExporterIsPresented = true
            }
        }
        .fileExporter(isPresented: $fileExporterIsPresented, item: source, contentTypes: [.plyFile], onCompletion: { result in
            print(result)
        })
    }
}

extension Path {
    static func star(sides: N, innerRadius: Double, outerRadius: Double) -> Path {
        let points = (0 ..< sides).map { i -> CGPoint in
            let angle = 2 * .pi * Double(i) / Double(sides)
            let radius = i.isMultiple(of: 2) ? innerRadius : outerRadius
            return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
        }
        return Path(points)
    }
}

// let font = CTFontCreateWithName("Apple Color Emoji" as CFString, 20, nil)
// let glyph = CTFontGetGlyphWithName(font, "numbersign" as CFString)
// let cgPath = CTFontCreatePathForGlyph(font, glyph, nil)!
// let path = Path(cgPath)
//            for x in 0..<65535 {
//                let name = CTFontCopyNameForGlyph(font, UInt16(x))
//                if let name {
//                    print(name)
//                }
//            }
