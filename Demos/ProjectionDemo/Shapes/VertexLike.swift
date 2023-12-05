import simd
import SIMDSupport

protocol VertexLike: Equatable {
    associatedtype Vector: PointLike

    var position: Vector { get set }
}

protocol VertexLike3: VertexLike where Vector: PointLike3 {
    var normal: Vector { get set }
}

struct SimpleVertex: VertexLike3 {
    var _position: PackedFloat3
    var _normal: PackedFloat3
    var textureCoordinate: SIMD2<Float>

    var position: SIMD3<Float> {
        get {
            return SIMD3<Float>(_position)
        }
        set {
            _position = PackedFloat3(newValue)
        }
    }

    var normal: SIMD3<Float> {
        get {
            return SIMD3<Float>(_normal)
        }
        set {
            _normal = PackedFloat3(newValue)
        }
    }

    init(position: SIMD3<Float>, normal: SIMD3<Float>, textureCoordinate: SIMD2<Float> = .zero) {
        self._position = PackedFloat3(position)
        self._normal = PackedFloat3(normal)
        self.textureCoordinate = textureCoordinate
    }
}
