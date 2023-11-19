import SwiftUI
import CoreGraphicsSupport
import Algorithms
import Everything
import earcut
import CoreText

struct ExtrusionView: View {
    var body: some View {
        SoftwareRendererView { projection, context2D, context3D in
            let path = Path(CGSize(1, 1))
            let polygons = path.polygonalChains.filter { $0.isClosed }.map { Polygon(polygonalChain: $0)}
            let meshes = polygons.map { $0.extrude(min: 0, max: 3, topCap: true, bottomCap: true) }
            for mesh in meshes {
                var rasterizer = context3D.rasterizer
                for (index, polygon) in mesh.toPolygons().enumerated() {
                    rasterizer.submit(polygon: polygon.map { $0 }, with: .color(Color(rgb: kellyColors[index % kellyColors.count])))
                }
                rasterizer.rasterize()
            }
        }
    }
}

extension PolygonalChain where Point == CGPoint {
    func extrude(min: Float, max: Float) -> TrivialMesh<UInt, SIMD3<Float>> {
        let quads: [Quad<SIMD3<Float>>] = vertices.windows(ofCount: 2).reduce(into: []) { result, window in
            let from = SIMD2<Float>(window.first!)
            let to = SIMD2<Float>(window.last!)
            let quad = Quad(vertices: (
                // TODO: Invent way to control which axis is extruded
                SIMD3<Float>(from, min),
                SIMD3<Float>(from, max),
                SIMD3<Float>(to, min),
                SIMD3<Float>(to, max)
            ))
            result.append(quad)
        }
        let mesh = TrivialMesh<UInt,SIMD3<Float>>(quads: quads)
        return mesh
    }
}

extension Polygon where Vertex == CGPoint {
    func extrude(min: Float, max: Float, topCap: Bool, bottomCap: Bool) -> TrivialMesh<UInt, SIMD3<Float>> {
        let walls = PolygonalChain(polygon: self).extrude(min: min, max: max)
        let topCap = topCap ? triangulate(z: max) : nil
        let bottomCap = bottomCap ? triangulate(z: min).flipped() : nil
        return TrivialMesh.merging(meshes: Array([walls, topCap, bottomCap].compacted()))
    }

    func triangulate(z: Float = 0) -> TrivialMesh<UInt, SIMD3<Float>> {
        let vertices = vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), z) }
        let indices = earcut(polygons: [vertices.map { $0.xy }]).map({ UInt($0) })
        return TrivialMesh(indices: indices, vertices: vertices)
    }
}

//let font = CTFontCreateWithName("Apple Color Emoji" as CFString, 20, nil)
//let glyph = CTFontGetGlyphWithName(font, "numbersign" as CFString)
//let cgPath = CTFontCreatePathForGlyph(font, glyph, nil)!
//let path = Path(cgPath)
//            for x in 0..<65535 {
//                let name = CTFontCopyNameForGlyph(font, UInt16(x))
//                if let name {
//                    print(name)
//                }
//            }
