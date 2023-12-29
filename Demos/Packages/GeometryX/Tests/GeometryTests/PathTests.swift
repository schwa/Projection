@testable import GeometryX
import SwiftUI
import XCTest

class PathTests: XCTestCase {
    func testElements() {
        let path = Path(lines: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)])
        XCTAssertEqual(path.elements.count, 2)
        XCTAssertEqual(path.elements[0], .move(to: CGPoint(x: 0, y: 0)))
        XCTAssertEqual(path.elements[1], .line(to: CGPoint(x: 10, y: 10)))
    }

    func testElementsEmpty() {
        let emptyPath = Path()

        XCTAssertEqual(emptyPath.elements.count, 0)
    }
}
