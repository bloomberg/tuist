import Basic
import Foundation
import TuistCore
import TuistGenerator
import TuistSupport
import XCTest

@testable import ProjectDescription
@testable import TuistLoader
@testable import TuistLoaderTesting
@testable import TuistSupportTesting

class GeneratorModelLoaderTests: TuistUnitTestCase {
    typealias WorkspaceManifest = ProjectDescription.Workspace
    typealias ProjectManifest = ProjectDescription.Project
    typealias TargetManifest = ProjectDescription.Target
    typealias SettingsManifest = ProjectDescription.Settings
    typealias ConfigurationManifest = ProjectDescription.Configuration
    typealias HeadersManifest = ProjectDescription.Headers
    typealias SchemeManifest = ProjectDescription.Scheme
    typealias BuildActionManifest = ProjectDescription.BuildAction
    typealias TestActionManifest = ProjectDescription.TestAction
    typealias RunActionManifest = ProjectDescription.RunAction
    typealias ArgumentsManifest = ProjectDescription.Arguments

    private var manifestLinter: MockManifestLinter!

    override func setUp() {
        super.setUp()
        manifestLinter = MockManifestLinter()
    }

    override func tearDown() {
        manifestLinter = nil
        super.tearDown()
    }

    func test_loadProject() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let manifests = [
            temporaryPath: ProjectManifest.test(name: "SomeProject"),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeProject")
    }

    func test_loadProject_withTargets() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let targetA = TargetManifest.test(name: "A")
        let targetB = TargetManifest.test(name: "B")
        let manifests = [
            temporaryPath: ProjectManifest.test(name: "Project",
                                                targets: [
                                                    targetA,
                                                    targetB,
                                                ]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.targets.count, 2)
        try XCTAssertTargetMatchesManifest(target: model.targets[0], matches: targetA, at: temporaryPath, generatorPaths: generatorPaths)
        try XCTAssertTargetMatchesManifest(target: model.targets[1], matches: targetB, at: temporaryPath, generatorPaths: generatorPaths)
    }

    func test_loadProject_withManifestTargetOptionDisabled() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        try createFiles([
            "TuistConfig.swift",
        ])
        let projects = [
            temporaryPath: ProjectManifest.test(name: "Project",
                                                targets: [
                                                    .test(name: "A"),
                                                    .test(name: "B"),
                                                ]),
        ]

        let configs = [
            temporaryPath: TuistConfig.test(generationOptions: []),
        ]

        let manifestLoader = createManifestLoader(with: projects, configs: configs)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.targets.map(\.name), [
            "A",
            "B",
        ])
    }

    func test_loadProject_withAdditionalFiles() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let files = try createFiles([
            "Documentation/README.md",
            "Documentation/guide.md",
        ])

        let manifests = [
            temporaryPath: ProjectManifest.test(name: "SomeProject",
                                                additionalFiles: [
                                                    "Documentation/**/*.md",
                                                ]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.additionalFiles, files.map { .file(path: $0) })
    }

    func test_loadProject_withFolderReferences() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let files = try createFolders([
            "Stubs",
        ])

        let manifests = [
            temporaryPath: ProjectManifest.test(name: "SomeProject",
                                                additionalFiles: [
                                                    .folderReference(path: "Stubs"),
                                                ]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.additionalFiles, files.map { .folderReference(path: $0) })
    }

    func test_loadProject_withCustomName() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        try createFiles([
            "TuistConfig.swift",
        ])

        let manifests = [
            temporaryPath: ProjectManifest.test(name: "SomeProject",
                                                additionalFiles: [
                                                    .folderReference(path: "Stubs"),
                                                ]),
        ]
        let configs = [
            temporaryPath: ProjectDescription.TuistConfig.test(generationOptions: [.xcodeProjectName("one \(.projectName) two")]),
        ]
        let manifestLoader = createManifestLoader(with: manifests, configs: configs)
        let subject = GeneratorModelLoader(manifestLoader: manifestLoader,
                                           manifestLinter: manifestLinter)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.fileName, "one SomeProject two")
    }

    func test_loadProject_withCustomNameDuplicates() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        try createFiles([
            "TuistConfig.swift",
        ])

        let manifests = [
            temporaryPath: ProjectManifest.test(name: "SomeProject",
                                                additionalFiles: [
                                                    .folderReference(path: "Stubs"),
                                                ]),
        ]
        let configs = [
            temporaryPath: ProjectDescription.TuistConfig.test(generationOptions: [.xcodeProjectName("one \(.projectName) two"),
                                                                                   .xcodeProjectName("two \(.projectName) three")]),
        ]
        let manifestLoader = createManifestLoader(with: manifests, configs: configs)
        let subject = GeneratorModelLoader(manifestLoader: manifestLoader,
                                           manifestLinter: manifestLinter)

        // When
        let model = try subject.loadProject(at: temporaryPath)

        // Then
        XCTAssertEqual(model.fileName, "one SomeProject two")
    }

    func test_loadWorkspace() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let manifests = [
            temporaryPath: WorkspaceManifest.test(name: "SomeWorkspace"),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadWorkspace(at: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.projects, [])
    }

    func test_loadWorkspace_withProjects() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let projects = try createFolders([
            "A",
            "B",
        ])

        let manifests = [
            temporaryPath: WorkspaceManifest.test(name: "SomeWorkspace", projects: ["A", "B"]),
        ]

        let manifestLoader = createManifestLoader(with: manifests, projects: projects)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadWorkspace(at: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.projects, projects)
    }

    func test_loadWorkspace_withAdditionalFiles() throws {
        let temporaryPath = try self.temporaryPath()
        let files = try createFiles([
            "Documentation/README.md",
            "Documentation/setup/README.md",
            "Playground.playground",
        ])

        let manifests = [
            temporaryPath: WorkspaceManifest.test(name: "SomeWorkspace",
                                                  projects: [],
                                                  additionalFiles: [
                                                      "Documentation/**/*.md",
                                                      "*.playground",
                                                  ]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadWorkspace(at: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.additionalFiles, files.map { .file(path: $0) })
    }

    func test_loadWorkspace_withFolderReferences() throws {
        let temporaryPath = try self.temporaryPath()
        try createFiles([
            "Documentation/README.md",
            "Documentation/setup/README.md",
        ])

        let manifests = [
            temporaryPath: WorkspaceManifest.test(name: "SomeWorkspace",
                                                  projects: [],
                                                  additionalFiles: [
                                                      .folderReference(path: "Documentation"),
                                                  ]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadWorkspace(at: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.additionalFiles, [
            .folderReference(path: temporaryPath.appending(RelativePath("Documentation"))),
        ])
    }

    func test_loadWorkspace_withInvalidProjectsPaths() throws {
        // Given
        let temporaryPath = try self.temporaryPath()

        let manifests = [
            temporaryPath: WorkspaceManifest.test(name: "SomeWorkspace", projects: ["A", "B"]),
        ]

        let manifestLoader = createManifestLoader(with: manifests)
        let subject = createGeneratorModelLoader(with: manifestLoader)

        // When
        let model = try subject.loadWorkspace(at: temporaryPath)

        // Then
        XCTAssertPrinterOutputContains("""
        No projects found at: A
        No projects found at: B
        """)
        XCTAssertEqual(model.projects, [])
    }

    func test_dependency_when_cocoapods() throws {
        // Given
        let dependency = TargetDependency.cocoapods(path: "./path/to/project")
        let generatorPaths = GeneratorPaths(manifestDirectory: AbsolutePath("/"))

        // When
        let got = try TuistCore.Dependency.from(manifest: dependency, generatorPaths: generatorPaths)

        // Then
        guard case let .cocoapods(path) = got else {
            XCTFail("Dependency should be cocoapods")
            return
        }
        XCTAssertEqual(path, AbsolutePath("/path/to/project"))
    }

    func test_dependency_when_localPackage() throws {
        // Given
        let dependency = TargetDependency.package(product: "library")
        let generatorPaths = GeneratorPaths(manifestDirectory: AbsolutePath("/"))

        // When
        let got = try TuistCore.Dependency.from(manifest: dependency, generatorPaths: generatorPaths)

        // Then
        guard
            case let .package(product) = got
        else {
            XCTFail("Dependency should be package")
            return
        }
        XCTAssertEqual(product, "library")
    }

    func test_headers() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try createFiles([
            "Sources/public/A1.h",
            "Sources/public/A1.m",
            "Sources/public/A2.h",
            "Sources/public/A2.m",

            "Sources/private/B1.h",
            "Sources/private/B1.m",
            "Sources/private/B2.h",
            "Sources/private/B2.m",

            "Sources/project/C1.h",
            "Sources/project/C1.m",
            "Sources/project/C2.h",
            "Sources/project/C2.m",
        ])

        let manifest = HeadersManifest(public: "Sources/public/**",
                                       private: "Sources/private/**",
                                       project: "Sources/project/**")

        // When
        let model = try TuistCore.Headers.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(model.public, [
            "Sources/public/A1.h",
            "Sources/public/A2.h",
        ].map { temporaryPath.appending(RelativePath($0)) })

        XCTAssertEqual(model.private, [
            "Sources/private/B1.h",
            "Sources/private/B2.h",
        ].map { temporaryPath.appending(RelativePath($0)) })

        XCTAssertEqual(model.project, [
            "Sources/project/C1.h",
            "Sources/project/C2.h",
        ].map { temporaryPath.appending(RelativePath($0)) })
    }

    func test_headersArray() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try createFiles([
            "Sources/public/A/A1.h",
            "Sources/public/A/A1.m",
            "Sources/public/B/B1.h",
            "Sources/public/B/B1.m",

            "Sources/private/C/C1.h",
            "Sources/private/C/C1.m",
            "Sources/private/D/D1.h",
            "Sources/private/D/D1.m",

            "Sources/project/E/E1.h",
            "Sources/project/E/E1.m",
            "Sources/project/F/F1.h",
            "Sources/project/F/F1.m",
        ])

        let manifest = HeadersManifest(public: ["Sources/public/A/*.h", "Sources/public/B/*.h"],
                                       private: ["Sources/private/C/*.h", "Sources/private/D/*.h"],
                                       project: ["Sources/project/E/*.h", "Sources/project/F/*.h"])

        // When
        let model = try TuistCore.Headers.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(model.public, [
            "Sources/public/A/A1.h",
            "Sources/public/B/B1.h",
        ].map { temporaryPath.appending(RelativePath($0)) })

        XCTAssertEqual(model.private, [
            "Sources/private/C/C1.h",
            "Sources/private/D/D1.h",
        ].map { temporaryPath.appending(RelativePath($0)) })

        XCTAssertEqual(model.project, [
            "Sources/project/E/E1.h",
            "Sources/project/F/F1.h",
        ].map { temporaryPath.appending(RelativePath($0)) })
    }

    func test_headersStringAndArrayMix() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try createFiles([
            "Sources/public/A/A1.h",
            "Sources/public/A/A1.m",

            "Sources/project/C/C1.h",
            "Sources/project/C/C1.m",
            "Sources/project/D/D1.h",
            "Sources/project/D/D1.m",
        ])

        let manifest = HeadersManifest(public: "Sources/public/A/*.h",
                                       project: ["Sources/project/C/*.h", "Sources/project/D/*.h"])

        // When
        let model = try TuistCore.Headers.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(model.public, [
            "Sources/public/A/A1.h",
        ].map { temporaryPath.appending(RelativePath($0)) })

        XCTAssertEqual(model.project, [
            "Sources/project/C/C1.h",
            "Sources/project/D/D1.h",
        ].map { temporaryPath.appending(RelativePath($0)) })
    }

    func test_coreDataModel() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try FileHandler.shared.touch(temporaryPath.appending(component: "model.xcdatamodeld"))
        let manifest = ProjectDescription.CoreDataModel("model.xcdatamodeld",
                                                        currentVersion: "1")

        // When
        let model = try TuistCore.CoreDataModel.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertTrue(try coreDataModel(model, matches: manifest, at: temporaryPath, generatorPaths: generatorPaths))
    }

    func test_targetActions() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.TargetAction.test(name: "MyScript",
                                                            tool: "my_tool",
                                                            path: "my/path",
                                                            order: .pre,
                                                            arguments: ["arg1", "arg2"])
        // When
        let model = try TuistCore.TargetAction.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(model.name, "MyScript")
        XCTAssertEqual(model.tool, "my_tool")
        XCTAssertEqual(model.path, temporaryPath.appending(RelativePath("my/path")))
        XCTAssertEqual(model.order, .pre)
        XCTAssertEqual(model.arguments, ["arg1", "arg2"])
    }

    func test_scheme_withoutActions() throws {
        // Given
        let manifest = SchemeManifest.test(name: "Scheme",
                                           shared: false)
        let projectPath = AbsolutePath("/somepath/Project")
        let generatorPaths = GeneratorPaths(manifestDirectory: projectPath)

        // When
        let model = try TuistCore.Scheme.from(manifest: manifest, projectPath: projectPath, generatorPaths: generatorPaths)

        // Then
        try assert(scheme: model, matches: manifest, path: projectPath, generatorPaths: generatorPaths)
    }

    func test_scheme_withActions() throws {
        // Given
        let arguments = ArgumentsManifest.test(environment: ["FOO": "BAR", "FIZ": "BUZZ"],
                                               launch: ["--help": true,
                                                        "subcommand": false])

        let projectPath = AbsolutePath("/somepath")
        let generatorPaths = GeneratorPaths(manifestDirectory: projectPath)

        let buildAction = BuildActionManifest.test(targets: ["A", "B"])
        let runActions = RunActionManifest.test(config: .release,
                                                executable: "A",
                                                arguments: arguments)
        let testAction = TestActionManifest.test(targets: ["B"],
                                                 arguments: arguments,
                                                 config: .debug,
                                                 coverage: true)
        let manifest = SchemeManifest.test(name: "Scheme",
                                           shared: true,
                                           buildAction: buildAction,
                                           testAction: testAction,
                                           runAction: runActions)

        // When
        let model = try TuistCore.Scheme.from(manifest: manifest, projectPath: projectPath, generatorPaths: generatorPaths)

        // Then
        try assert(scheme: model, matches: manifest, path: projectPath, generatorPaths: generatorPaths)
    }

    func test_fileElement_warning_withDirectoryPathsAsFiles() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try createFiles([
            "Documentation/README.md",
            "Documentation/USAGE.md",
        ])

        let manifest = ProjectDescription.FileElement.glob(pattern: "Documentation")

        // When
        let model = try TuistCore.FileElement.from(manifest: manifest,
                                                   path: temporaryPath,
                                                   generatorPaths: generatorPaths,
                                                   includeFiles: { !FileHandler.shared.isFolder($0) })

        // Then
        let documentationPath = temporaryPath.appending(component: "Documentation").pathString
        XCTAssertPrinterOutputContains("'\(documentationPath)' is a directory, try using: '\(documentationPath)/**' to list its files")
        XCTAssertEqual(model, [])
    }

    func test_fileElement_warning_withMisingPaths() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.FileElement.glob(pattern: "Documentation/**")

        // When
        let model = try TuistCore.FileElement.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        let documentationPath = temporaryPath.appending(RelativePath("Documentation/**"))
        XCTAssertPrinterOutputContains("No files found at: \(documentationPath)")
        XCTAssertEqual(model, [])
    }

    func test_fileElement_warning_withInvalidFolderReference() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        try createFiles([
            "README.md",
        ])

        let manifest = ProjectDescription.FileElement.folderReference(path: "README.md")

        // When
        let model = try TuistCore.FileElement.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertPrinterOutputContains("README.md is not a directory - folder reference paths need to point to directories")
        XCTAssertEqual(model, [])
    }

    func test_fileElement_warning_withMissingFolderReference() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.FileElement.folderReference(path: "Documentation")

        // When
        let model = try TuistCore.FileElement.from(manifest: manifest, path: temporaryPath, generatorPaths: generatorPaths)

        // Then
        XCTAssertPrinterOutputContains("Documentation does not exist")
        XCTAssertEqual(model, [])
    }

    func test_deploymentTarget() throws {
        // Given
        let manifest: ProjectDescription.DeploymentTarget = .iOS(targetVersion: "13.1", devices: .iphone)

        // When
        let got = TuistCore.DeploymentTarget.from(manifest: manifest)

        // Then
        guard
            case let .iOS(version, devices) = got
        else {
            XCTFail("Deployment target should be iOS")
            return
        }

        XCTAssertEqual(version, "13.1")
        XCTAssertTrue(devices.contains(.iphone))
        XCTAssertFalse(devices.contains(.ipad))
    }

    // MARK: - Helpers

    func createGeneratorModelLoader(with manifestLoader: ManifestLoading) -> GeneratorModelLoader {
        GeneratorModelLoader(manifestLoader: manifestLoader,
                             manifestLinter: manifestLinter)
    }

    func createManifestLoader(with projects: [AbsolutePath: ProjectDescription.Project],
                              configs: [AbsolutePath: ProjectDescription.TuistConfig] = [:]) -> ManifestLoading {
        let manifestLoader = MockManifestLoader()
        manifestLoader.loadProjectStub = { path in
            guard let manifest = projects[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.loadTuistConfigStub = { path in
            guard let manifest = configs[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.manifestsAtStub = { path in
            var manifests = Set<Manifest>()
            if projects[path] != nil {
                manifests.insert(.project)
            }

            if configs[path] != nil {
                manifests.insert(.tuistConfig)
            }
            return manifests
        }
        return manifestLoader
    }

    func createManifestLoader(with workspaces: [AbsolutePath: ProjectDescription.Workspace],
                              projects: [AbsolutePath] = []) -> ManifestLoading {
        let manifestLoader = MockManifestLoader()
        manifestLoader.loadWorkspaceStub = { path in
            guard let manifest = workspaces[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.manifestsAtStub = { path in
            projects.contains(path) ? Set([.project]) : Set([])
        }
        return manifestLoader
    }

    private func resolveProjectPath(projectPath: Path?, defaultPath: AbsolutePath, generatorPaths: GeneratorPaths) throws -> AbsolutePath {
        if let projectPath = projectPath { return try generatorPaths.resolve(path: projectPath) }
        return defaultPath
    }
}
