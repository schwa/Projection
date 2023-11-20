import simd
import SwiftUI

public struct Rasterizer {

    public struct Options {
        public var drawNormals = false
        public var shadeFragmentsWithNormals = false
        public var fill = true
        public var stroke = false
        public var backfaceCulling = true

        public static var `default`: Self {
            return .init()
        }
    }

    struct Fragment {
        var modelSpaceVertices: [SIMD3<Float>]
        var clipSpaceVertices: [SIMD4<Float>]
        var clipSpaceMin: SIMD3<Float>
        var modelSpaceNormal: SIMD3<Float>

        var shading: GraphicsContext.Shading

        init(vertices: [SIMD3<Float>], projection: Projection3D, shading: GraphicsContext.Shading) {
            self.modelSpaceVertices = vertices
            let transform = projection.clipTransform * projection.projectionTransform * projection.viewTransform
            self.clipSpaceVertices = modelSpaceVertices.map {
                transform * SIMD4<Float>($0, 1.0)
            }
            self.clipSpaceMin = clipSpaceVertices.reduce(.zero) { result, vertex in
                return SIMD3<Float>(min(result.x, vertex.x), min(result.y, vertex.y), min(result.z, vertex.z))
            }
            let a = modelSpaceVertices[0]
            let b = modelSpaceVertices[1]
            let c = modelSpaceVertices[2]
            modelSpaceNormal = simd_normalize(simd_cross(b - a, c - a))

            self.shading = shading
        }
    }

    public var graphicsContext: GraphicsContext3D
    var fragments: [Fragment] = []
    public var options: Options

    public mutating func submit(polygon: [SIMD3<Float>], with shading: GraphicsContext.Shading) {
        fragments.append(Fragment(vertices: polygon, projection: graphicsContext.projection, shading: shading))
    }

    public mutating func rasterize() {
        let fragments = fragments
        .filter {
            // TODO: Do actual frustrum culling.
            $0.clipSpaceMin.z <= 0
        }
        .sorted { lhs, rhs in
            lhs.clipSpaceMin.z < rhs.clipSpaceMin.z
        }
        for fragment in fragments {
            let viewSpaceNormal = (graphicsContext.projection.viewTransform * SIMD4(fragment.modelSpaceNormal, 1.0)).xyz
            let backFacing = simd_dot(viewSpaceNormal, .zero) < 0
            if options.backfaceCulling && backFacing {
                continue
            }
            let lines = fragment.clipSpaceVertices.map {
                let screenSpace = SIMD3($0.x, $0.y, $0.z) / $0.w
                return CGPoint(x: Double(screenSpace.x), y: Double(screenSpace.y))
            }

            let path = Path { path in
                path.addLines(lines)
                path.closeSubpath()
            }

            let shading = !options.shadeFragmentsWithNormals ? fragment.shading : .color(viewSpaceNormal)

            if options.fill {
                graphicsContext.graphicsContext2D.fill(path, with: shading)
            }
            if options.stroke {
                graphicsContext.graphicsContext2D.stroke(path, with: shading, style: .init(lineCap: .round))
            }

            if options.drawNormals {
                let center = (fragment.modelSpaceVertices.reduce(.zero, +) / Float(fragment.modelSpaceVertices.count))
                let path = Path3D { path in
                    path.move(to: center)
                    path.addLine(to: center + fragment.modelSpaceNormal)
                }
                graphicsContext.stroke(path: path, with: .color(fragment.modelSpaceNormal))
            }
        }
    }
}
