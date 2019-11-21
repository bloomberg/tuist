import Basic
import Foundation
import TuistCore
import TuistCoreTesting
import TuistSupport
import XcodeProj
import XCTest

@testable import TuistGenerator
@testable import TuistSupportTesting

final class WorkspaceSchemeGeneratorTests: XCTestCase {
    var subject: WorkspaceSchemesGenerator!

    override func setUp() {
        super.setUp()
        subject = WorkspaceSchemesGenerator()
    }
    
    func test_schemeBuildAction_whenSingleProject() throws {
        // Given
        let scheme = Scheme.test(buildAction: BuildAction(targets: [TargetReference(projectPath: "Projects/Project", name: "App")]))
        let projectPath = "/somepath/Workspace/Projects/Project"
        
        let app = Target.test(name: "App", product: .app)
        let targets = [app]
        
        let project = Project.test(path: AbsolutePath(projectPath))
        let graph = Graph.create(dependencies: [
                                                (project: project, target: app, dependencies: [])
                                                ])
        
        // Then
        let got = try subject.schemeBuildAction(scheme: scheme,
                                                graph: graph,
                                                rootPath: AbsolutePath("/somepath/Workspace"),
                                                generatedProjects: [AbsolutePath(projectPath):
                                                    generatedProject(targets: targets, projectPath: "\(projectPath)/project.xcodeproj")])

        // When
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.buildActionEntries.count, 1)
        let entry = try XCTUnwrap(result.buildActionEntries.first)
        let buildableReference = entry.buildableReference
        XCTAssertEqual(entry.buildFor, [.analyzing, .archiving, .profiling, .running, .testing])

        XCTAssertEqual(buildableReference.referencedContainer, "container:Projects/Project/project.xcodeproj")
        XCTAssertEqual(buildableReference.buildableName, "App.app")
        XCTAssertEqual(buildableReference.blueprintName, "App")
        XCTAssertEqual(buildableReference.buildableIdentifier, "primary")

        XCTAssertEqual(result.parallelizeBuild, true)
        XCTAssertEqual(result.buildImplicitDependencies, true)
    }
    
    func test_schemeBuildAction_whenMultipleProject() throws {
        // Given
        let scheme = Scheme.test(buildAction: BuildAction(targets: [
                                                                    TargetReference(projectPath: "Projects/ProjectA", name: "FrameworkA"),
                                                                    TargetReference(projectPath: "Projects/ProjectB", name: "FrameworkB")
                                                                    ]))
        let projectAPath = "/somepath/Workspace/Projects/ProjectA"
        let projectBPath = "/somepath/Workspace/Projects/ProjectB"
        
        let frameworkA = Target.test(name: "FrameworkA", product: .staticFramework)
        let frameworkB = Target.test(name: "FrameworkB", product: .staticFramework)
        let targets = [frameworkA, frameworkB]
        
        let projectA = Project.test(path: AbsolutePath(projectAPath))
        let projectB = Project.test(path: AbsolutePath(projectBPath))
        let graph = Graph.create(dependencies: [
                                                (project: projectA, target: frameworkA, dependencies: []),
                                                (project: projectB, target: frameworkB, dependencies: [])
                                                ])
        
        // Then
        let got = try subject.schemeBuildAction(scheme: scheme,
                                                graph: graph,
                                                rootPath: AbsolutePath("/somepath/Workspace"),
                                                generatedProjects: [
                                                                    AbsolutePath(projectAPath): generatedProject(targets: targets, projectPath: "\(projectAPath)/project.xcodeproj"),
                                                                    AbsolutePath(projectBPath): generatedProject(targets: targets, projectPath: "\(projectBPath)/project.xcodeproj")
                                                                    ])

        // When
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.buildActionEntries.count, 2)
        let firstEntry = try XCTUnwrap(result.buildActionEntries[0])
        let firstBuildableReference = firstEntry.buildableReference
        
        XCTAssertEqual(firstEntry.buildFor, [.analyzing, .archiving, .profiling, .running, .testing])
        let secondEntry = try XCTUnwrap(result.buildActionEntries[1])
        let secondBuildableReference = secondEntry.buildableReference
        XCTAssertEqual(secondEntry.buildFor, [.analyzing, .archiving, .profiling, .running, .testing])

        XCTAssertEqual(firstBuildableReference.referencedContainer, "container:Projects/ProjectA/project.xcodeproj")
        XCTAssertEqual(firstBuildableReference.buildableName, "FrameworkA.framework")
        XCTAssertEqual(firstBuildableReference.blueprintName, "FrameworkA")
        XCTAssertEqual(firstBuildableReference.buildableIdentifier, "primary")
        
        XCTAssertEqual(secondBuildableReference.referencedContainer, "container:Projects/ProjectB/project.xcodeproj")
        XCTAssertEqual(secondBuildableReference.buildableName, "FrameworkB.framework")
        XCTAssertEqual(secondBuildableReference.blueprintName, "FrameworkB")
        XCTAssertEqual(secondBuildableReference.buildableIdentifier, "primary")

        XCTAssertEqual(result.parallelizeBuild, true)
        XCTAssertEqual(result.buildImplicitDependencies, true)
    }
    
    func test_schemeTestAction() throws {
        // Given
        let scheme = Scheme.test(testAction: TestAction(targets: [TargetReference(projectPath: "Projects/Project", name: "AppTests")], configurationName: "Release"))
        let projectPath = "/somepath/Workspace/Projects/Project"
        
        let app = Target.test(name: "App", product: .app)
        let appTests = Target.test(name: "AppTests", product: .unitTests)
        let targets = [app, appTests]
               
        let project = Project.test(path: AbsolutePath(projectPath))
        let graph = Graph.create(dependencies: [
                                                (project: project, target: app, dependencies: []),
                                                (project: project, target: appTests, dependencies: [app])])
        
        let generatedProjectWithTests = generatedProject(targets: targets, projectPath: "\(projectPath)/project.xcodeproj")
        
        // When
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: AbsolutePath("/somepath/Workspace"), generatedProjects: [AbsolutePath(projectPath): generatedProjectWithTests])
        
        // Then
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.buildConfiguration, "Release")
        XCTAssertEqual(result.shouldUseLaunchSchemeArgsEnv, true)
        XCTAssertNil(result.macroExpansion)
        let testable = try XCTUnwrap(result.testables.first)
        let buildableReference = testable.buildableReference

        XCTAssertEqual(testable.skipped, false)
        XCTAssertEqual(buildableReference.referencedContainer, "container:Projects/Project/project.xcodeproj")
        XCTAssertEqual(buildableReference.buildableName, "AppTests.xctest")
        XCTAssertEqual(buildableReference.blueprintName, "AppTests")
        XCTAssertEqual(buildableReference.buildableIdentifier, "primary")
    }
    
    func test_schemeLaunchAction() throws {
        // Given
        let scheme = Scheme.test(runAction: RunAction(configurationName: "Release", executable: TargetReference(projectPath: "Projects/Project", name: "App"), arguments:       Arguments(environment:["a": "b"], launch: ["some": true])))
        
        let projectPath = "/somepath/Workspace/Projects/Project"
        
        let app = Target.test(name: "App", product: .app, environment: ["a": "b"])
        let pbxTarget = PBXNativeTarget(name: "App")
               
        let project = Project.test(path: AbsolutePath(projectPath))
        let graph = Graph.create(dependencies: [(project: project, target: app, dependencies: [])])
        
        let generatedProject = GeneratedProject.test(path: AbsolutePath("\(projectPath)/project.xcodeproj"), targets: ["App": pbxTarget])
        
        // When
        let got = try subject.schemeLaunchAction(scheme: scheme, graph: graph, rootPath: AbsolutePath("/somepath/Workspace"), generatedProjects: [AbsolutePath(projectPath): generatedProject])
        
        // Then
        let result = try XCTUnwrap(got)
        
        XCTAssertNil(result.macroExpansion)

        let buildableReference = try XCTUnwrap(result.runnable?.buildableReference)

        XCTAssertEqual(result.buildConfiguration, "Release")
        XCTAssertEqual(result.environmentVariables, [XCScheme.EnvironmentVariable(variable: "a", value: "b", enabled: true)])
        XCTAssertEqual(buildableReference.referencedContainer, "container:Projects/Project/project.xcodeproj")
        XCTAssertEqual(buildableReference.buildableName, "App.app")
        XCTAssertEqual(buildableReference.blueprintName, "App")
        XCTAssertEqual(buildableReference.buildableIdentifier, "primary")
        
    }
    
    // TODO profile action tests
    
    private func generatedProject(targets: [Target], projectPath: String = "/project.xcodeproj") -> GeneratedProject {
        var pbxTargets: [String: PBXNativeTarget] = [:]
        targets.forEach { pbxTargets[$0.name] = PBXNativeTarget(name: $0.name) }
        return GeneratedProject(pbxproj: .init(), path: AbsolutePath(projectPath), targets: pbxTargets, name: "project.xcodeproj")
    }
}
