#if os(visionOS)
import Foundation
import SwiftUI
import RealityKit

public struct MeshView: View {
    let mesh: TrivialMesh <UInt32, SimpleVertex>

    public init(mesh: TrivialMesh<UInt32, SimpleVertex>) {
        self.mesh = mesh
    }

    public var body: some View {
        RealityView { content in
            let entity = try! ModelEntity(trivialMesh: mesh)
            entity.orientation = .init(angle: .pi / 2, axis: [1, 0, 0])
            print(entity.visualBounds(relativeTo: nil))
            content.add(entity)
        }
    }
}

#Preview {
    MeshView(mesh: TrivialMesh(cylinder: Cylinder(radius: 0.1, depth: 0.01), segments: 24))
    //MeshView(mesh: TrivialMesh(circleRadius: 1, segments: 24))
}
#endif
