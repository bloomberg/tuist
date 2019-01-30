import Basic
import Foundation
@testable import TuistGenerator

extension Dependency {

    static func test(name: String? = "Dependency",
                     type: String = "framework",
                     target: String? = "Target",
                     path: RelativePath? = RelativePath("Dependency"),
                     publicHeaders: RelativePath? = nil,
                     swiftModuleMap: String? = nil) -> Dependency {
        return Dependency(name: name,
                          type: type,
                          target: target,
                          path: path,
                          publicHeaders: publicHeaders,
                          swiftModuleMap: swiftModuleMap)
    }
}
