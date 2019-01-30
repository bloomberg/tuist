import Basic
import Foundation
@testable import TuistCoreTesting
@testable import TuistKit
import Utility
import xcodeproj
import XCTest

final class FocusCommandTests: XCTestCase {
    var subject: FocusCommand!
    var generator: MockGenerator!
    var parser: ArgumentParser!
    var printer: MockPrinter!
    var fileHandler: MockFileHandler!
    var opener: MockOpener!
    var system: MockSystem!
    var resourceLocator: MockResourceLocator!

    override func setUp() {
        super.setUp()
        printer = MockPrinter()
        generator = MockGenerator()
        parser = ArgumentParser.test()
        fileHandler = try! MockFileHandler()
        opener = MockOpener()
        system = MockSystem()
        resourceLocator = MockResourceLocator()

        subject = FocusCommand(parser: parser,
                               printer: printer,
                               fileHandler: fileHandler,
                               generator: generator,
                               opener: opener)
    }

    func test_command() {
        XCTAssertEqual(FocusCommand.command, "focus")
    }

    func test_overview() {
        XCTAssertEqual(FocusCommand.overview, "Opens Xcode ready to focus on the project in the current directory.")
    }

    func test_run_fatalErrors_when_theworkspaceGenerationFails() throws {
        let result = try parser.parse([FocusCommand.command, "-c", "Debug"])
        let error = NSError.test()
        generator.generateWorkspaceStub = { _, _ -> AbsolutePath in
            throw error
        }
        XCTAssertThrowsError(try subject.run(with: result)) {
            XCTAssertEqual($0 as NSError?, error)
        }
    }

    func test_run() throws {
        let result = try parser.parse([FocusCommand.command, "-c", "Debug"])
        let workspacePath = AbsolutePath("/test.xcworkspace")
        generator.generateWorkspaceStub = { _, _ -> AbsolutePath in
            return workspacePath
        }
        try subject.run(with: result)

        XCTAssertEqual(opener.openArgs.last, workspacePath)
    }
}
