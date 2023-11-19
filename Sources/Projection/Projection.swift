import simd
import SwiftUI

public struct Projection3D {
    public var size: CGSize
    public var projectionTransform = simd_float4x4(diagonal: .init(repeating: 1))
    public var viewTransform = simd_float4x4(diagonal: .init(repeating: 1))
    public var clipTransform = simd_float4x4(diagonal: .init(repeating: 1))

    public init(size: CGSize, projectionTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1]), viewTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1]), clipTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1])) {
        self.size = size
        self.projectionTransform = projectionTransform
        self.viewTransform = viewTransform
        self.clipTransform = clipTransform
    }

    public func project(_ point: SIMD3<Float>) -> CGPoint {
        var point = clipTransform * projectionTransform * viewTransform * SIMD4<Float>(point, 1.0)
        point /= point.w
        return CGPoint(x: Double(point.x), y: Double(point.y))
    }
}

// MARK: -

public extension GraphicsContext {
    func draw3DLayer(projection: Projection3D, content: (inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        drawLayer { context in
            context.translateBy(x: projection.size.width / 2, y: projection.size.height / 2)
            var graphicsContext = GraphicsContext3D(graphicsContext2D: context, projection: projection)
            content(&context, &graphicsContext)
        }
    }
}

public struct GraphicsContext3D {
    public var graphicsContext2D: GraphicsContext
    public var projection: Projection3D
    public var rasterizerOptions: Rasterizer.Options

    public var rasterizer: Rasterizer {
        Rasterizer(graphicsContext: self, options: rasterizerOptions)
    }

    public init(graphicsContext2D: GraphicsContext, projection: Projection3D) {
        self.graphicsContext2D = graphicsContext2D
        self.projection = projection
        self.rasterizerOptions = .default
    }

    public func stroke(path: Path3D, with shading: GraphicsContext.Shading) {
        let viewProjectionTransform = projection.projectionTransform * projection.viewTransform
        let path = Path { path2D in
            for element in path.elements {
                switch element {
                case .move(let point):
                    let transform = projection.clipTransform * viewProjectionTransform
                    var point = transform * SIMD4<Float>(point, 1.0)
                    point /= point.w
                    path2D.move(to: CGPoint(x: Double(point.x), y: Double(point.y)))
                case .addLine(let point):
                    let transform = projection.clipTransform * viewProjectionTransform
                    var point = transform * SIMD4<Float>(point, 1.0)
                    point /= point.w
                    path2D.addLine(to: CGPoint(x: Double(point.x), y: Double(point.y)))
                case .closePath:
                    path2D.closeSubpath()
                }
            }
        }
        graphicsContext2D.stroke(path, with: shading)
    }
}

// MARK: -

public struct Path3D {
    public enum Element {
        case move(to: SIMD3<Float>)
        case addLine(to: SIMD3<Float>)
        case closePath
    }

    public var elements: [Element] = []

    public init() {
    }

    public init(builder: (inout Path3D) -> Void) {
        var path = Path3D()
        builder(&path)
        self = path
    }

    public mutating func move(to: SIMD3<Float>) {
        elements.append(.move(to: to))
    }

    public mutating func addLine(to: SIMD3<Float>) {
        elements.append(.addLine(to: to))
    }

    public mutating func closePath() {
        elements.append(.closePath)
    }
}

// MARK: -

public struct Rasterizer {

    public struct Options {
        public var drawNormals = false
        public var shadeFragmentsWithNormals = false
        public var fill = true
        public var stroke = false

        public static var `default`: Self {
            return .init()
        }
    }


    struct Fragment {
        var modelSpaceVertices: [SIMD3<Float>]
        var clipSpaceVertices: [SIMD4<Float>]
        var clipSpaceZ: Float
        var modelSpaceNormal: SIMD3<Float>

        var shading: GraphicsContext.Shading

        init(vertices: [SIMD3<Float>], projection: Projection3D, shading: GraphicsContext.Shading) {
            self.modelSpaceVertices = vertices
            let transform = projection.clipTransform * projection.projectionTransform * projection.viewTransform
            self.clipSpaceVertices = modelSpaceVertices.map {
                transform * SIMD4<Float>($0, 1.0)
            }
            self.clipSpaceZ = clipSpaceVertices.map(\.z).min()!
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
            $0.clipSpaceZ <= 0
        }
        .sorted { lhs, rhs in
            lhs.clipSpaceZ < rhs.clipSpaceZ
        }
        for fragment in fragments {
            let viewSpaceNormal = (graphicsContext.projection.viewTransform * SIMD4(fragment.modelSpaceNormal, 1.0)).xyz
            let backFacing = simd_dot(viewSpaceNormal, graphicsContext.projection.viewTransform.translation) < 0
            if backFacing {
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

            let shading = !options.shadeFragmentsWithNormals ? fragment.shading : .color(fragment.modelSpaceNormal)

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

internal extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

internal extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        return [x, y, z]
    }
}

internal extension GraphicsContext.Shading {
    static func color(_ rgb: SIMD3<Float>) -> Self {
        return .color(Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)))
    }
}