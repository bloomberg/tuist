import Basic
import Foundation
import TuistCore
@testable import TuistCoreTesting
@testable import TuistKit
import Utility
import xcodeproj
import XCTest

final class GenerateCommandTests: XCTestCase {
    var subject: GenerateCommand!
    var errorHandler: MockErrorHandler!
    var manifestLoader: MockManifestLoader!
    var generator: MockGenerator!
    var parser: ArgumentParser!
    var printer: MockPrinter!
    var resourceLocator: ResourceLocator!

    override func setUp() {
        super.setUp()
        printer = MockPrinter()
        errorHandler = MockErrorHandler()
        generator = MockGenerator()
        parser = ArgumentParser.test()
        resourceLocator = ResourceLocator()
        manifestLoader = MockManifestLoader()
        subject = GenerateCommand(parser: parser,
                                  printer: printer,
                                  manifestLoader: manifestLoader,
                                  generator: generator)
    }

    func test_command() {
        XCTAssertEqual(GenerateCommand.command, "generate")
    }

    func test_overview() {
        XCTAssertEqual(GenerateCommand.overview, "Generates an Xcode workspace to start working on the project.")
    }

    func test_run_fatalErrors_when_theworkspaceGenerationFails() throws {
        let result = try parser.parse([GenerateCommand.command])
        let error = NSError.test()
        manifestLoader.manifestsAtStub = { _ in
            return Set([.workspace])
        }
        generator.generateWorkspaceStub = { _, _ -> AbsolutePath in
            throw error
        }
        XCTAssertThrowsError(try subject.run(with: result)) {
            XCTAssertEqual($0 as NSError?, error)
        }
    }

    func test_run_prints() throws {
        let result = try parser.parse([GenerateCommand.command])
        manifestLoader.manifestsAtStub = { _ in
            return Set([.project])
        }
        try subject.run(with: result)
        XCTAssertEqual(printer.printSuccessArgs.first, "Project generated.")
    }
}
