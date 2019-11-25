import Basic
import Foundation
import TuistCore
import TuistSupport
import XCTest

@testable import TuistKit
@testable import TuistSupportTesting

final class ProjectEditorMapperTests: TuistUnitTestCase {
    var subject: ProjectEditorMapper!

    override func setUp() {
        super.setUp()
        subject = ProjectEditorMapper()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func test_edit_when_there_are_helpers() throws {
        // Given
        let sourceRootPath = try temporaryPath()
        let manifestPaths = [sourceRootPath].map { $0.appending(component: "Project.swift") }
        let helperPaths = [sourceRootPath].map { $0.appending(component: "Project+Template.swift") }
        let projectDescriptionPath = sourceRootPath.appending(component: "ProjectDescription.framework")

        // When
        let (project, graph) = subject.map(sourceRootPath: sourceRootPath,
                                           manifests: manifestPaths,
                                           helpers: helperPaths,
                                           projectDescriptionPath: projectDescriptionPath)

        // Then
        let manifestsTarget = project.targets.first
        let helpersTarget = project.targets.last
        let expectedManifestsTarget = Target(name: "Manifests",
                                             platform: .macOS,
                                             product: .staticFramework,
                                             productName: "Manifests",
                                             bundleId: "io.tuist.${PRODUCT_NAME:rfc1034identifier}",
                                             settings: expectedSettings(sourceRootPath: sourceRootPath),
                                             sources: manifestPaths.map { (path: $0, compilerFlags: nil) },
                                             filesGroup: .group(name: "Manifests"),
                                             dependencies: [.target(name: "ProjectDescriptionHelpers")])
        let expectedHelpersTarget = Target(name: "ProjectDescriptionHelpers",
                                           platform: .macOS,
                                           product: .staticFramework,
                                           productName: "ProjectDescriptionHelpers",
                                           bundleId: "io.tuist.${PRODUCT_NAME:rfc1034identifier}",
                                           settings: expectedSettings(sourceRootPath: sourceRootPath),
                                           sources: helperPaths.map { (path: $0, compilerFlags: nil) },
                                           filesGroup: .group(name: "Manifests"),
                                           dependencies: [])
        let expectedProject = Project(path: sourceRootPath,
                                      name: "Manifests",
                                      settings: Settings(base: [:],
                                                         configurations: Settings.default.configurations,
                                                         defaultSettings: .recommended),
                                      filesGroup: .group(name: "Manifests"),
                                      targets: [expectedManifestsTarget, expectedHelpersTarget])
        XCTAssertEqual(project, expectedProject)

        let targetNodes = graph.targets.sorted(by: { $0.target.name < $1.target.name })
        XCTAssertEqual(targetNodes.count, 2)
        XCTAssertEqual(targetNodes.first?.target, manifestsTarget)
        XCTAssertEqual(targetNodes.last?.target, helpersTarget)
        XCTAssertEqual(targetNodes.first?.dependencies, [targetNodes.last!])
    }

    func test_edit_when_there_are_no_helpers() throws {
        // Given
        let sourceRootPath = try temporaryPath()
        let manifestPaths = [sourceRootPath].map { $0.appending(component: "Project.swift") }
        let helperPaths: [AbsolutePath] = []
        let projectDescriptionPath = sourceRootPath.appending(component: "ProjectDescription.framework")

        // When
        let (project, graph) = subject.map(sourceRootPath: sourceRootPath,
                                           manifests: manifestPaths,
                                           helpers: helperPaths,
                                           projectDescriptionPath: projectDescriptionPath)

        // Then
        let manifestsTarget = project.targets.first
        XCTAssertEqual(project.targets.count, 1)

        let expectedManifestsTarget = Target(name: "Manifests",
                                             platform: .macOS,
                                             product: .staticFramework,
                                             productName: "Manifests",
                                             bundleId: "io.tuist.${PRODUCT_NAME:rfc1034identifier}",
                                             settings: expectedSettings(sourceRootPath: sourceRootPath),
                                             sources: manifestPaths.map { (path: $0, compilerFlags: nil) },
                                             filesGroup: .group(name: "Manifests"),
                                             dependencies: [])
        let expectedProject = Project(path: sourceRootPath,
                                      name: "Manifests",
                                      settings: Settings(base: [:],
                                                         configurations: Settings.default.configurations,
                                                         defaultSettings: .recommended),
                                      filesGroup: .group(name: "Manifests"),
                                      targets: [expectedManifestsTarget])
        XCTAssertEqual(project, expectedProject)

        let targetNodes = graph.targets.sorted(by: { $0.target.name < $1.target.name })
        XCTAssertEqual(targetNodes.count, 1)
        XCTAssertEqual(targetNodes.first?.target, manifestsTarget)
        XCTAssertEqual(targetNodes.first?.dependencies, [])
    }

    fileprivate func expectedSettings(sourceRootPath: AbsolutePath) -> Settings {
        let base: [String: SettingValue] = [
            "FRAMEWORK_SEARCH_PATHS": .string(sourceRootPath.pathString),
            "LIBRARY_SEARCH_PATHS": .string(sourceRootPath.pathString),
            "SWIFT_INCLUDE_PATHS": .string(sourceRootPath.pathString),
            "SWIFT_VERSION": .string(Constants.swiftVersion),
        ]
        return Settings(base: base,
                        configurations: Settings.default.configurations,
                        defaultSettings: .recommended)
    }
}
