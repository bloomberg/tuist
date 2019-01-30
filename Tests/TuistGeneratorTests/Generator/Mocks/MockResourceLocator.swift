import Basic
import Foundation
@testable import TuistGenerator

final class MockResourceLocator: ResourceLocating {
    var productsDirectoryPathCount: UInt = 0
    var productsDirectoryPathStub: (() throws -> AbsolutePath)?

    func productsDirectoryPath() throws -> AbsolutePath {
        productsDirectoryPathCount += 1
        return try productsDirectoryPathStub?() ?? AbsolutePath("/")
    }
}
