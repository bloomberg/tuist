import Basic
import Foundation
import TuistCore
import TuistSupport
import XcodeProj

/// Protocol that defines the interface of the schemes generation.
protocol WorkspaceSchemesGenerating {
    /// Generates the schemes for the workspace targets.
    ///
    /// - Parameters:
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Throws: A FatalError if the generation of the schemes fails.
    func generateWorkspaceSchemes(workspace: Workspace,
                                  xcworkspacePath: AbsolutePath,
                                  generatedProjects: [AbsolutePath: GeneratedProject],
                                  graph: Graphing) throws
}

final class WorkspaceSchemesGenerator: WorkspaceSchemesGenerating {
    func generateWorkspaceSchemes(workspace: Workspace, xcworkspacePath: AbsolutePath, generatedProjects: [AbsolutePath : GeneratedProject], graph: Graphing) throws {
        try workspace.schemes.forEach { scheme in
            try generateScheme(scheme: scheme, xcworkspacePath: xcworkspacePath, workspacePath: workspace.path, graph: graph, generatedProjects: generatedProjects)
        }
    }
    
    // Generates the schemes for a workspace.
    func generateScheme(scheme: Scheme,
                        xcworkspacePath: AbsolutePath,
                        workspacePath: AbsolutePath,
                        graph: Graphing,
                        generatedProjects: [AbsolutePath: GeneratedProject]) throws {
        let schemeDirectory = try createSchemesDirectory(path: xcworkspacePath, shared: scheme.shared)
        let schemePath = schemeDirectory.appending(component: "\(scheme.name).xcscheme")
        let generatedBuildAction = try schemeBuildAction(scheme: scheme,
                                                         graph: graph,
                                                         rootPath: workspacePath,
                                                         generatedProjects: generatedProjects)
        
        let scheme = XCScheme(name: scheme.name,
                              lastUpgradeVersion: SchemesGenerator.defaultLastUpgradeVersion,
                              version: SchemesGenerator.defaultVersion,
                              buildAction: generatedBuildAction)
        try scheme.write(path: schemePath.path, override: true)
    }
    
    /// Generates the scheme build action.
    ///
    /// - Parameters:
    ///   - scheme: Scheme manifest.
    ///   - graph: Graph of tuist dependencies.
    ///   - rootPath: Path to the workspace.
    ///   - generatedProjects: Generated Xcode project.
    /// - Returns: Scheme build action.
    func schemeBuildAction(scheme: Scheme,
                           graph: Graphing,
                           rootPath: AbsolutePath,
                           generatedProject: GeneratedProject? = nil,
                           generatedProjects: [AbsolutePath: GeneratedProject]? = nil,
                           project: Project? = nil) throws -> XCScheme.BuildAction? {
        guard let buildAction = scheme.buildAction else { return nil }

        let buildFor: [XCScheme.BuildAction.Entry.BuildFor] = [
            .analyzing, .archiving, .profiling, .running, .testing,
        ]

        var entries: [XCScheme.BuildAction.Entry] = []
        var preActions: [XCScheme.ExecutionAction] = []
        var postActions: [XCScheme.ExecutionAction] = []

        try buildAction.targets.forEach { buildActionTarget in
            guard let projectPath = buildActionTarget.projectPath else { return }
            let pathToProject = rootPath.appending(RelativePath(projectPath))
            guard let target = try graph.target(path: pathToProject,
                                                name: buildActionTarget.targetName) else { return }
            guard let generatedProject = generatedProjects[pathToProject] else { return }
            guard let pbxTarget = generatedProject.targets[buildActionTarget.targetName] else { return }
            let relativeXcodeProjectPath = generatedProject.path.relative(to: rootPath)
                
            let buildableReference = self.targetBuildableReference(target: target.target,
                                                                   pbxTarget: pbxTarget,
                                                                   projectPath: relativeXcodeProjectPath.pathString)

            entries.append(XCScheme.BuildAction.Entry(buildableReference: buildableReference, buildFor: buildFor))
        }
        
        if let project = project, let generatedProject = generatedProjects[project.path] {
            preActions = schemeExecutionActions(actions: buildAction.preActions,
                                                project: project,
                                                generatedProject: generatedProject)

            postActions = schemeExecutionActions(actions: buildAction.postActions,
                                                 project: project,
                                                 generatedProject: generatedProject)
        }
        

        return XCScheme.BuildAction(buildActionEntries: entries,
                                    preActions: preActions,
                                    postActions: postActions,
                                    parallelizeBuild: true,
                                    buildImplicitDependencies: true)
    }
}
