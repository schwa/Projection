import CoreGraphics
import simd

struct Box<Point: PointLike> {
    var min: Point
    var max: Point

    init(min: Point, max: Point) {
        self.min = min
        self.max = max
    }
}

// MARK: -

struct Line<Point: PointLike> {
    var point: Point
    var direction: Point // TODO: Vector not Point.

    init(point: Point, direction: Point) {
        assert(direction != .zero)
        self.point = point
        self.direction = direction
    }
}

extension Line {
    init(_ segment: LineSegment<Point>) {
        self.init(point: segment.start, direction: segment.direction)
    }
}

// MARK: -

struct LineSegment<Point: PointLike> {
    var start: Point
    var end: Point

    init(start: Point, end: Point) {
        self.start = start
        self.end = end
    }
}

extension LineSegment {
    var direction: Point {
        end - start
    }

    var length: Point.Scalar {
        direction.length
    }

    var lengthSquared: Point.Scalar {
        direction.lengthSquared
    }

    var normalizedDirection: Point {
        direction / length
    }

    func point(at t: Point.Scalar) -> Point {
        start + direction * t
    }
}

// MARK: -

struct Plane {
    var normal: SIMD3<Float>
    var w: Float

    init(normal: SIMD3<Float>, w: Float) {
        self.normal = normal
        self.w = w
    }
}

extension Plane {
    init(points: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
        let (a, b, c) = points
        let n = simd.cross(b - a, c - a).normalized
        self.init(normal: n, w: simd.dot(n, a))
    }
}

extension Plane {
    mutating func flip() {
        normal = -normal
        w = -w
    }

    func flipped() -> Plane {
        var plane = self
        plane.flip()
        return plane
    }
}

// MARK: -

struct Polygon<Vertex> {
    var vertices: [Vertex]

    init(vertices: [Vertex]) {
        self.vertices = vertices
    }
}

extension Polygon where Vertex: VertexLike3 {
    mutating func flip() {
        vertices = vertices.reversed().map { vertex in
            var vertex = vertex
            vertex.normal = -vertex.normal
            return vertex
        }
    }

    func flipped() -> Self {
        var copy = self
        copy.flip()
        return copy
    }
}

extension Polygon where Vertex: VertexLike3, Vertex.Vector == SIMD3<Float> {
    var plane: Plane {
        Plane(points: (vertices[0].position, vertices[1].position, vertices[2].position))
    }
}

extension Polygon where Vertex == SIMD3<Float> {
    var plane: Plane {
        Plane(points: (vertices[0], vertices[1], vertices[2]))
    }
}

extension Polygon where Vertex: PointLike {
    init(polygonalChain: PolygonalChain<Vertex>) {
        self.init(vertices: polygonalChain.isClosed ? polygonalChain.vertices.dropLast() : polygonalChain.vertices)
    }
}

// MARK: -

struct PolygonalChain<Point> {
    var vertices: [Point]

    init() {
        vertices = []
    }

    init(vertices: [Point]) {
        self.vertices = vertices
    }
}

extension PolygonalChain where Point: PointLike {
    var isClosed: Bool {
        vertices.first == vertices.last
    }

    var segments: [LineSegment<Point>] {
        zip(vertices, vertices.dropFirst()).map(LineSegment.init)
    }

    var isSelfIntersecting: Bool {
        fatalError()
    }
}

extension PolygonalChain where Point == SIMD3<Float> {
    var isCoplanar: Bool {
        if vertices.count <= 3 {
            return true
        }
        let normal = simd.cross(segments[0].direction, segments[1].direction)
        for segment in segments.dropFirst(2) {
            if simd.dot(segment.direction, normal) != 0 {
                return false
            }
        }
        return true
    }
}

extension PolygonalChain {
    init(polygon: Polygon<Point>) {
        vertices = polygon.vertices + [polygon.vertices[0]]
    }
}

// MARK: -

struct Quad<Point: PointLike> {
    var vertices: (Point, Point, Point, Point)

    init(vertices: (Point, Point, Point, Point)) {
        self.vertices = vertices
    }
}

extension Quad {
    func subdivide() -> (Triangle<Point>, Triangle<Point>) {
        // 1---3
        // |\  |
        // | \ |
        // |  \|
        // 0---2
        (
            Triangle(vertices: (vertices.0, vertices.1, vertices.2)),
            Triangle(vertices: (vertices.1, vertices.3, vertices.2))
        )
    }
}

// MARK: -

struct Ray {
    var origin: SIMD3<Float>
    var direction: SIMD3<Float>

    init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
        self.origin = origin
        self.direction = direction
    }
}

// MARK: -

struct Sphere {
    var center: SIMD3<Float>
    var radius: Float

    init(center: SIMD3<Float>, radius: Float) {
        self.center = center
        self.radius = radius
    }
}

// MARK: -

struct Triangle<Point: PointLike> {
    var vertices: (Point, Point, Point)

    init(vertices: (Point, Point, Point)) {
        self.vertices = vertices
    }
}

extension Triangle {
    var reversed: Triangle {
        .init(vertices: (vertices.2, vertices.1, vertices.0))
    }
}
