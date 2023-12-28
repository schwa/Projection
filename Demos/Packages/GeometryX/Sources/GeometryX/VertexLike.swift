import simd
import SIMDSupport

public protocol VertexLike: Equatable {
    associatedtype Vector: PointLike

    var position: Vector { get set }
}

public protocol VertexLike3: VertexLike where Vector: PointLike3 {
    var normal: Vector { get set }
}

public struct SimpleVertex: VertexLike3 {
    // Note: Order can be important when interacting with Metal APIs etc.
    public var packedPosition : PackedFloat3
    public var packedNormal: PackedFloat3
    public var textureCoordinate: SIMD2<Float>

    public var position: SIMD3<Float> {
        get {
            return SIMD3<Float>(packedPosition)
        }
        set {
            packedPosition = PackedFloat3(newValue)
        }
    }

    public var normal: SIMD3<Float> {
        get {
            return SIMD3<Float>(packedNormal)
        }
        set {
            packedNormal = PackedFloat3(newValue)
        }
    }

    public init(position: SIMD3<Float>, normal: SIMD3<Float>, textureCoordinate: SIMD2<Float> = .zero) {
        self.packedPosition = PackedFloat3(position)
        self.packedNormal = PackedFloat3(normal)
        self.textureCoordinate = textureCoordinate
    }
}

extension SIMD3 <Float>: VertexLike {
    public var position: SIMD3<Float> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}
