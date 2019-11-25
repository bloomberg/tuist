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
    
    // MARK: - Build Action Tests

    func test_schemeBuildAction_whenSingleProject() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Workspace/Projects/Project")
        let scheme = Scheme.test(buildAction: BuildAction(targets: [TargetReference(projectPath: projectPath, name: "App")]))
        
        let app = Target.test(name: "App", product: .app)
        let targets = [app]
        
        let project = Project.test(path: projectPath)
        let graph = Graph.create(dependencies: [(project: project, target: app, dependencies: [])])
        
        // Then
        let got = try subject.schemeBuildAction(scheme: scheme,
                                                graph: graph,
                                                rootPath: AbsolutePath("/somepath/Workspace"),
                                                generatedProjects: [projectPath:
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
        let projectAPath = AbsolutePath("/somepath/Workspace/Projects/ProjectA")
        let projectBPath = AbsolutePath("/somepath/Workspace/Projects/ProjectB")
        
        let buildAction = BuildAction(targets: [
            TargetReference(projectPath: projectAPath, name: "FrameworkA"),
            TargetReference(projectPath: projectBPath, name: "FrameworkB")
        ])
        let scheme = Scheme.test(buildAction: buildAction)
        
        let frameworkA = Target.test(name: "FrameworkA", product: .staticFramework)
        let frameworkB = Target.test(name: "FrameworkB", product: .staticFramework)
        let targets = [frameworkA, frameworkB]
        
        let projectA = Project.test(path: projectAPath)
        let projectB = Project.test(path: projectBPath)
        let graph = Graph.create(dependencies: [
            (project: projectA, target: frameworkA, dependencies: []),
            (project: projectB, target: frameworkB, dependencies: [])
        ])
        
        // Then
        let got = try subject.schemeBuildAction(scheme: scheme,
                                                graph: graph,
                                                rootPath: AbsolutePath("/somepath/Workspace"),
                                                generatedProjects: [
                                                                    projectAPath: generatedProject(targets: targets, projectPath: "\(projectAPath)/project.xcodeproj"),
                                                                    projectBPath: generatedProject(targets: targets, projectPath: "\(projectBPath)/project.xcodeproj")
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
    
    func test_schemeBuildAction_with_executionAction() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Project")
        let target = Target.test(name: "App", product: .app)
        let preAction = ExecutionAction(title: "Pre Action", scriptText: "echo Pre Actions", target: TargetReference(projectPath: projectPath, name: "App"))
        let postAction = ExecutionAction(title: "Post Action", scriptText: "echo Post Actions", target: TargetReference(projectPath: projectPath, name: "App"))
        let buildAction = BuildAction.test(targets: [TargetReference(projectPath: projectPath, name: "Library")], preActions: [preAction], postActions: [postAction])

        let scheme = Scheme.test(name: "App", shared: true, buildAction: buildAction)
        let project = Project.test(path: projectPath, targets: [target])
        let graph = Graph.create(dependencies: [
            (project: project, target: target, dependencies: [])
        ])

        // When
        let got = try subject.schemeBuildAction(scheme: scheme,
                                                graph: graph,
                                                rootPath: projectPath,
                                                generatedProjects: createGeneratedProjects(projects: [project]))

        // Then
        XCTAssertEqual(got?.preActions.first?.title, "Pre Action")
        XCTAssertEqual(got?.preActions.first?.scriptText, "echo Pre Actions")

        let preBuildableReference = got?.preActions.first?.environmentBuildable

        XCTAssertEqual(preBuildableReference?.referencedContainer, "container:project.xcodeproj")
        XCTAssertEqual(preBuildableReference?.buildableName, "App.app")
        XCTAssertEqual(preBuildableReference?.blueprintName, "App")
        XCTAssertEqual(preBuildableReference?.buildableIdentifier, "primary")

        XCTAssertEqual(got?.postActions.first?.title, "Post Action")
        XCTAssertEqual(got?.postActions.first?.scriptText, "echo Post Actions")

        let postBuildableReference = got?.postActions.first?.environmentBuildable

        XCTAssertEqual(postBuildableReference?.referencedContainer, "container:project.xcodeproj")
        XCTAssertEqual(postBuildableReference?.buildableName, "App.app")
        XCTAssertEqual(postBuildableReference?.blueprintName, "App")
        XCTAssertEqual(postBuildableReference?.buildableIdentifier, "primary")
    }
    
    // MARK: - Test Action Tests

    func test_schemeTestAction() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Workspace/Projects/Project")

        let scheme = Scheme.test(testAction: TestAction(targets: [TargetReference(projectPath: projectPath, name: "AppTests")], configurationName: "Release"))
        
        let app = Target.test(name: "App", product: .app)
        let appTests = Target.test(name: "AppTests", product: .unitTests)
        let targets = [app, appTests]
               
        let project = Project.test(path: projectPath)
        let graph = Graph.create(dependencies: [
                                                (project: project, target: app, dependencies: []),
                                                (project: project, target: appTests, dependencies: [app])])
        
        let generatedProjectWithTests = generatedProject(targets: targets, projectPath: "\(projectPath)/project.xcodeproj")
        
        // When
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: AbsolutePath("/somepath/Workspace"), generatedProjects: [projectPath: generatedProjectWithTests])
        
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
    
    func test_schemeTestAction_when_notTestsTarget() throws {
        // Given
        let scheme = Scheme.test()
        let project = Project.test()
        let generatedProject = GeneratedProject.test()
        let graph = Graph.create(dependencies: [])

        // Then
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: project.path, generatedProjects: [project.path: generatedProject])

        // When
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.buildConfiguration, "Debug")
        XCTAssertEqual(result.shouldUseLaunchSchemeArgsEnv, false)
        XCTAssertNil(result.macroExpansion)
        XCTAssertEqual(result.testables.count, 0)
    }
    
    func test_schemeTestAction_when_testsTarget() throws {
        // Given
        let target = Target.test(name: "App", product: .app)
        let testTarget = Target.test(name: "AppTests", product: .unitTests)
        let project = Project.test(targets: [target, testTarget])
        
        let testAction = TestAction.test(targets: [TargetReference(projectPath: project.path, name: "AppTests")],
                                         arguments: nil)
        
        
        let scheme = Scheme.test(name: "AppTests", testAction: testAction)
        let generatedProjects = createGeneratedProjects(projects: [project])
        
        let graph = Graph.create(dependencies: [(project: project, target: target, dependencies: []),
                                                (project: project, target: testTarget, dependencies: [target])])
        
        // When
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: project.path, generatedProjects: generatedProjects)
    
        // Then
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.buildConfiguration, "Debug")
        XCTAssertEqual(result.shouldUseLaunchSchemeArgsEnv, true)
        XCTAssertNil(result.macroExpansion)
        let testable = try XCTUnwrap(result.testables.first)
        let buildableReference = testable.buildableReference

        XCTAssertEqual(testable.skipped, false)
        XCTAssertEqual(buildableReference.referencedContainer, "container:Project.xcodeproj")
        XCTAssertEqual(buildableReference.buildableName, "AppTests.xctest")
        XCTAssertEqual(buildableReference.blueprintName, "AppTests")
        XCTAssertEqual(buildableReference.buildableIdentifier, "primary")
    }
    
    func test_schemeTestAction_with_executionAction() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Project")
        let testTarget = Target.test(name: "AppTests", product: .unitTests)

        let preAction = ExecutionAction(title: "Pre Action", scriptText: "echo Pre Actions", target: TargetReference(projectPath: projectPath, name: "AppTests"))
        let postAction = ExecutionAction(title: "Post Action", scriptText: "echo Post Actions", target: TargetReference(projectPath: projectPath, name: "AppTests"))
        let testAction = TestAction.test(targets: [TargetReference(projectPath: projectPath, name: "AppTests")], preActions: [preAction], postActions: [postAction])

        let scheme = Scheme.test(name: "AppTests", shared: true, testAction: testAction)
        let project = Project.test(path: projectPath, targets: [testTarget])

        let generatedProjects = createGeneratedProjects(projects: [project])
        let graph = Graph.create(dependencies: [(project: project, target: testTarget, dependencies: [])])

        // When
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: project.path, generatedProjects: generatedProjects)

        // Then
        // Pre Action
        let result = try XCTUnwrap(got)
        XCTAssertEqual(result.preActions.first?.title, "Pre Action")
        XCTAssertEqual(result.preActions.first?.scriptText, "echo Pre Actions")

        let preBuildableReference = try XCTUnwrap(result.preActions.first?.environmentBuildable)

        XCTAssertEqual(preBuildableReference.referencedContainer, "container:project.xcodeproj")
        XCTAssertEqual(preBuildableReference.buildableName, "AppTests.xctest")
        XCTAssertEqual(preBuildableReference.blueprintName, "AppTests")
        XCTAssertEqual(preBuildableReference.buildableIdentifier, "primary")

        // Post Action
        XCTAssertEqual(result.postActions.first?.title, "Post Action")
        XCTAssertEqual(result.postActions.first?.scriptText, "echo Post Actions")

        let postBuildableReference = try XCTUnwrap(result.postActions.first?.environmentBuildable)

        XCTAssertEqual(postBuildableReference.referencedContainer, "container:project.xcodeproj")
        XCTAssertEqual(postBuildableReference.buildableName, "AppTests.xctest")
        XCTAssertEqual(postBuildableReference.blueprintName, "AppTests")
        XCTAssertEqual(postBuildableReference.buildableIdentifier, "primary")
    }
    
    func test_schemeTestAction_with_codeCoverageTargets() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Project")

        let target = Target.test(name: "App", product: .app)
        let testTarget = Target.test(name: "AppTests", product: .unitTests)

        let testAction = TestAction.test(targets: [TargetReference(projectPath: projectPath, name: "AppTests")],
                                         coverage: true,
                                         codeCoverageTargets: [TargetReference(projectPath: projectPath, name: "App")])
        let buildAction = BuildAction.test(targets: [TargetReference(projectPath: projectPath, name: "App")])

        let scheme = Scheme.test(name: "AppTests", shared: true, buildAction: buildAction, testAction: testAction)
        
        let project = Project.test(path: projectPath, targets: [target, testTarget])
        let generatedProjects = createGeneratedProjects(projects: [project])
        let graph = Graph.create(dependencies: [(project: project, target: target, dependencies: []),
                                                (project: project, target: testTarget, dependencies: [target])])

        // When
        let got = try subject.schemeTestAction(scheme: scheme, graph: graph, rootPath: project.path, generatedProjects: generatedProjects)

        // Then
        let codeCoverageTargetsBuildableReference = got?.codeCoverageTargets

        XCTAssertEqual(got?.onlyGenerateCoverageForSpecifiedTargets, true)
        XCTAssertEqual(codeCoverageTargetsBuildableReference?.count, 1)
        XCTAssertEqual(codeCoverageTargetsBuildableReference?.first?.buildableName, "App.app")
    }
    
    // MARK: - Launch Action Tests

    func test_schemeLaunchAction() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Workspace/Projects/Project")

        let scheme = Scheme.test(runAction: RunAction(configurationName: "Release", executable: TargetReference(projectPath: projectPath, name: "App"), arguments: Arguments(environment:["a": "b"], launch: ["some": true])))
                
        let app = Target.test(name: "App", product: .app, environment: ["a": "b"])
        let pbxTarget = PBXNativeTarget(name: "App")
               
        let project = Project.test(path: projectPath)
        let graph = Graph.create(dependencies: [(project: project, target: app, dependencies: [])])
        
        let generatedProject = GeneratedProject.test(path: AbsolutePath("\(projectPath)/project.xcodeproj"), targets: ["App": pbxTarget])
        
        // When
        let got = try subject.schemeLaunchAction(scheme: scheme, graph: graph, rootPath: AbsolutePath("/somepath/Workspace"), generatedProjects: [projectPath: generatedProject])
        
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
    
    func test_schemeLaunchAction_when_notRunnableTarget() throws {
        // Given
        let projectPath = AbsolutePath("/somepath/Project")
        
        let target = Target.test(name: "Library", platform: .iOS, product: .dynamicLibrary)

        let buildAction = BuildAction.test(targets: [TargetReference(projectPath: projectPath, name: "Library")])
        let testAction = TestAction.test(targets: [TargetReference(projectPath: projectPath, name: "Library")])

        let scheme = Scheme.test(name: "Library", buildAction: buildAction, testAction: testAction, runAction: nil)
        let project = Project.test(path: projectPath, targets: [target])
        let graph = Graph.create(dependencies: [(project: project, target: target, dependencies: [])])

        // When
        let got = try subject.schemeLaunchAction(scheme: scheme,
                                                 graph: graph,
                                                 rootPath: projectPath,
                                                 generatedProjects: createGeneratedProjects(projects: [project]))

        // Then
        XCTAssertNil(got?.runnable?.buildableReference)

        XCTAssertEqual(got?.buildConfiguration, "Debug")
        XCTAssertEqual(got?.macroExpansion?.referencedContainer, "container:Project.xcodeproj")
        XCTAssertEqual(got?.macroExpansion?.buildableName, "libLibrary.dylib")
        XCTAssertEqual(got?.macroExpansion?.blueprintName, "Library")
        XCTAssertEqual(got?.macroExpansion?.buildableIdentifier, "primary")
    }
    
    private func createGeneratedProjects(projects: [Project]) -> [AbsolutePath: GeneratedProject] {
        return Dictionary(uniqueKeysWithValues: projects.map { ($0.path, generatedProject(targets: $0.targets, projectPath: $0.path.appending(component: "\($0.name).xcodeproj").pathString)) })
    }
    
    private func generatedProject(targets: [Target], projectPath: String = "/project.xcodeproj") -> GeneratedProject {
        var pbxTargets: [String: PBXNativeTarget] = [:]
        targets.forEach { pbxTargets[$0.name] = PBXNativeTarget(name: $0.name) }
        return GeneratedProject(pbxproj: .init(), path: AbsolutePath(projectPath), targets: pbxTargets, name: "project.xcodeproj")
    }
}
