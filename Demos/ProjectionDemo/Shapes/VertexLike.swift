import simd

protocol VertexLike: Equatable {
    associatedtype Vector: PointLike

    var position: Vector { get set }
}

protocol VertexLike3: VertexLike where Vector: PointLike3 {
    var normal: Vector { get set }
}

struct SimpleVertex: VertexLike3 {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>

    init(position: SIMD3<Float>, normal: SIMD3<Float>) {
        self.position = position
        self.normal = normal
    }
}
