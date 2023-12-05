import ModelIO
import RealityKit
import SIMDSupport

extension ModelComponent {
    init(mesh: TrivialMesh<some UnsignedInteger & BinaryInteger, SIMD3<Float>>) throws {
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffers.Positions(mesh.vertices)
        meshDescriptor.primitives = .triangles(mesh.indices.map { UInt32($0) })
        let meshResource = try MeshResource.generate(from: [meshDescriptor])
        self = ModelComponent(mesh: meshResource, materials: [])
    }
}
