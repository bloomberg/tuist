import Foundation
import XCTest
@testable import TuistKit

final class BuildConfigurationTests: XCTestCase {

    func test_predefined_debug() {
        // When
        let configuration = BuildConfiguration.debug

        // Then
        XCTAssertEqual(configuration.name, "Debug")
        XCTAssertEqual(configuration.predefined, true)
        XCTAssertEqual(configuration.variant, .debug)
        XCTAssertEqual(configuration.xcodeValue, "Debug")
    }

    func test_predefined_release() {
        // When
        let configuration = BuildConfiguration.release

        // Then
        XCTAssertEqual(configuration.name, "Release")
        XCTAssertEqual(configuration.predefined, true)
        XCTAssertEqual(configuration.variant, .release)
        XCTAssertEqual(configuration.xcodeValue, "Release")
    }

    func test_custom_debug() {
        // When
        let configuration = BuildConfiguration(name: "Custom", variant: .debug)

        // Then
        XCTAssertEqual(configuration.name, "Custom")
        XCTAssertEqual(configuration.predefined, false)
        XCTAssertEqual(configuration.variant, .debug)
        XCTAssertEqual(configuration.xcodeValue, "Custom")
    }

    func test_custom_release() {
        // When
        let configuration = BuildConfiguration(name: "Custom", variant: .release)

        // Then
        XCTAssertEqual(configuration.name, "Custom")
        XCTAssertEqual(configuration.predefined, false)
        XCTAssertEqual(configuration.variant, .release)
        XCTAssertEqual(configuration.xcodeValue, "Custom")
    }
}
