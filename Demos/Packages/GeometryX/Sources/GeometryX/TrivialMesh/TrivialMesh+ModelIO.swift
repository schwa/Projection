import Algorithms
import ModelIO
import SIMDSupport

public extension TrivialMesh where Index == UInt32, Vertex == SIMD3<Float> {
    init(url: URL) throws {
        let asset = MDLAsset(url: url)
        let mesh = asset.object(at: 0) as! MDLMesh

        guard let attribute = mesh.vertexDescriptor.attributes.compactMap({ $0 as? MDLVertexAttribute }).first(where: { $0.name == MDLVertexAttributePosition }) else {
            fatalError()
        }

        let layout = mesh.vertexDescriptor.layouts[attribute.bufferIndex] as! MDLVertexBufferLayout
        let positionBuffer = mesh.vertexBuffers[attribute.bufferIndex]
        let positionBytes = UnsafeRawBufferPointer(start: positionBuffer.map().bytes, count: positionBuffer.length)
        let positions = positionBytes.chunks(ofCount: layout.stride).map { slice in
            let start = slice.index(slice.startIndex, offsetBy: attribute.offset)
            let end = slice.index(start, offsetBy: 12) // TODO: assumes packed float 3
            let slice = slice[start ..< end]
            return slice.load(as: PackedFloat3.self) // TODO: assumes packed float 3
        }

        let submesh = mesh.submeshes![0] as! MDLSubmesh
        let indexBuffer = submesh.indexBuffer
        let indexBytes = UnsafeRawBufferPointer(start: indexBuffer.map().bytes, count: indexBuffer.length)
        let indices = indexBytes.bindMemory(to: UInt32.self)

        self.init(indices: Array(indices), vertices: Array(positions.map { SIMD3<Float>($0) }))
    }
}

public extension MDLMesh {
    convenience init(trivialMesh mesh: TrivialMesh<some UnsignedInteger & BinaryInteger, SimpleVertex>) {
        let vertexBuffer = mesh.vertices.withUnsafeBytes { buffer in
            MDLMeshBufferData(type: .vertex, data: Data(buffer))
        }
        let descriptor = MDLVertexDescriptor()
        // TODO: hard coded.
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0))
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeNormal, format: .float3, offset: 12, bufferIndex: 0))
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 24, bufferIndex: 0))
        descriptor.setPackedOffsets()
        descriptor.setPackedStrides()
        let indexType: MDLIndexBitDepth
        let indexBuffer: MDLMeshBuffer
        switch mesh.indices.count {
        case 0 ..< 256:
            indexType = .uInt8
            let indices = mesh.indices.map({ UInt8($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 256 ..< 65536:
            indexType = .uInt16
            let indices = mesh.indices.map({ UInt16($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 65536 ..< 4_294_967_296:
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

public extension TrivialMesh where Vertex == SimpleVertex {
    func write(to url: URL) throws {
        let asset = MDLAsset()
        let mesh = MDLMesh(trivialMesh: self)
        asset.add(mesh)
        try asset.export(to: url)
    }
}
