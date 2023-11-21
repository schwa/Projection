import simd
import SwiftUI

internal extension simd_float4x4 {
    var translation: SIMD3<Float> {
        columns.3.xyz
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
