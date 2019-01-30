import Basic
import Foundation
@testable import TuistGenerator
import XCTest

final class WorkspaceGeneratorTests: XCTestCase {
    var projectGenerator: MockProjectGenerator!
    var subject: WorkspaceGenerator!

    override func setUp() {
        super.setUp()
        projectGenerator = MockProjectGenerator()
    }
}
