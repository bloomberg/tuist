import Basic
import Foundation
import XCTest
@testable import TuistGenerator

final class GraphCircularDetectorTests: XCTestCase {
    var subject: GraphCircularDetecting!

    override func setUp() {
        super.setUp()
        subject = GraphCircularDetector()
    }

    func test_start_throws_when_a_circular_dependency_is_found() throws {
        try subject.start(from: node("a"), to: node("b"))
        try subject.start(from: node("b"), to: node("c"))
        XCTAssertThrowsError(try subject.start(from: node("c"), to: node("a"))) { error in
            XCTAssertEqual(error as? GraphLoadingError, GraphLoadingError.circularDependency(node("c"), node("a")))
        }
    }

    func test_complete() throws {
        try subject.start(from: node("a"), to: node("b"))
        try subject.start(from: node("b"), to: node("c"))
        try subject.start(from: node("b"), to: node("d"))
        subject.complete(node("a"))
    }

    func test_complete_when_two_points_to_same_node() throws {
        try subject.start(from: node("a"), to: node("b"))
        try subject.start(from: node("a"), to: node("c"))
        try subject.start(from: node("a"), to: node("c"))
        try subject.start(from: node("b"), to: node("d"))
        try subject.start(from: node("c"), to: node("d"))
        subject.complete(node("a"))
    }

    func test_two_root_nodes() throws {
        try subject.start(from: node("A"), to: node("B"))
        try subject.start(from: node("ATests"), to: node("A"))
        subject.complete(node("A"))
    }

    private func node(_ name: String) -> GraphCircularDetectorNode {
        return GraphCircularDetectorNode(path: AbsolutePath("/\(name)/"), name: name)
    }
}
