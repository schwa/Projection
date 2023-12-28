public protocol MeshConvertable {
    func toMesh() -> TrivialMesh<UInt, SIMD3<Float>>
}
