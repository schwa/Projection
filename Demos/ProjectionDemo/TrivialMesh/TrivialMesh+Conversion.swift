import RealityKit
import ModelIO
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

extension MDLMesh {
    convenience init(mesh: TrivialMesh<some UnsignedInteger & BinaryInteger, SIMD3<Float>>) {
        let vertexBuffer = mesh.vertices.map(PackedFloat3.init).withUnsafeBytes { buffer in
            return MDLMeshBufferData(type: .vertex, data: Data(buffer))
        }
        let descriptor = MDLVertexDescriptor()
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0))
        descriptor.setPackedOffsets()
        descriptor.setPackedStrides()
        let indexType: MDLIndexBitDepth
        let indexBuffer: MDLMeshBuffer
        switch mesh.indices.count {
        case 0..<256:
            indexType = .uInt8
            let indices = mesh.indices.map({ UInt8($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 256..<65536:
            indexType = .uInt16
            let indices = mesh.indices.map({ UInt16($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 65536..<4_294_967_296:
            indexType = .uInt32
            let indices = mesh.indices.map({ UInt32($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        default:
            fatalError()
        }
        let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: mesh.indices.count, indexType: indexType, geometryType: .triangles, material: nil)
        self.init(vertexBuffer: vertexBuffer, vertexCount: mesh.vertices.count, descriptor: descriptor, submeshes: [submesh])
    }
}
