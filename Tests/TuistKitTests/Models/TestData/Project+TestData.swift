import Basic
import Foundation
@testable import TuistKit

extension Project {
    static func test(path: AbsolutePath = AbsolutePath("/test/"),
                     name: String = "Project",
                     settings: Settings? = nil,
                     filesGroup: ProjectGroup = .group(name: "Project"),
                     targets: [Target] = [Target.test()]) -> Project {
        return Project(path: path,
                       name: name,
                       settings: settings ?? Settings.test(),
                       filesGroup: filesGroup,
                       targets: targets)
    }
}
