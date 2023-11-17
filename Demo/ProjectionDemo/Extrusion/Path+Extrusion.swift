import SwiftUI

extension Path {
    func extrude(transform: CGAffineTransform = .identity, minY: Float, maxY: Float) -> TrivialMesh<UInt, SIMD3<Float>>? {
        let segments = render(transform: transform)
        let sum = segments.map { ($0.end.x - $0.start.x) * ($0.end.y - $0.start.y) }.reduce(0, +)
        if sum == 0.0 {
            print("Skipping zero area polygon")
            return nil
        }
        let mesh = segments.extrude(minY: minY, maxY: maxY)
        return mesh
    }
}

