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
