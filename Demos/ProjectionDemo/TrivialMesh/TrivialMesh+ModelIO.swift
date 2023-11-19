import SwiftUI
import SIMDSupport
import Projection
import ModelIO
import Algorithms
import CoreGraphicsSupport
import SwiftFormats

extension TrivialMesh where Index == UInt32, Vertex == SIMD3<Float> {

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
