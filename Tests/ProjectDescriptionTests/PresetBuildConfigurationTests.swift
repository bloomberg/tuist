import Foundation
import TuistCoreTesting
import XCTest

@testable import ProjectDescription

final class PresetBuildConfigurationTests: XCTestCase {
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()

    func test_preset_names() {
        XCTAssertEqual(PresetBuildConfiguration.debug.name, "Debug")
        XCTAssertEqual(PresetBuildConfiguration.release.name, "Release")
    }
}
