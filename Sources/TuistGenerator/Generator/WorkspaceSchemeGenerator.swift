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
    /// Default last upgrade version for generated schemes.
    private static let defaultLastUpgradeVersion = "1010"

    /// Default version for generated schemes.
    private static let defaultVersion = "1.3"
    
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
                              lastUpgradeVersion: WorkspaceSchemesGenerator.defaultLastUpgradeVersion,
                              version: WorkspaceSchemesGenerator.defaultVersion,
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
                           generatedProjects: [AbsolutePath: GeneratedProject]) throws -> XCScheme.BuildAction? {
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
                                                name: buildActionTarget.name) else { return }
            guard let generatedProject = generatedProjects[pathToProject] else { return }
            guard let pbxTarget = generatedProject.targets[buildActionTarget.name] else { return }
            let relativeXcodeProjectPath = generatedProject.path.relative(to: rootPath)
                
            let buildableReference = self.targetBuildableReference(target: target.target,
                                                                   pbxTarget: pbxTarget,
                                                                   projectPath: relativeXcodeProjectPath.pathString)

            entries.append(XCScheme.BuildAction.Entry(buildableReference: buildableReference, buildFor: buildFor))
        }
        
        preActions = try buildAction.preActions.map {
            try schemeExecutionAction(action: $0, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath)
        }
        
        postActions = try buildAction.postActions.map {
            try schemeExecutionAction(action: $0, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath)
        }

        return XCScheme.BuildAction(buildActionEntries: entries,
                                    preActions: preActions,
                                    postActions: postActions,
                                    parallelizeBuild: true,
                                    buildImplicitDependencies: true)
    }

        
    /// Returns the scheme buildable reference for a given target.
    ///
    /// - Parameters:
    ///   - target: Target manifest.
    ///   - pbxTarget: Xcode native target.
    ///   - projectPath: Project name with the .xcodeproj extension.
    /// - Returns: Buildable reference.
    func targetBuildableReference(target: Target,
                                  pbxTarget: PBXNativeTarget,
                                  projectPath: String) -> XCScheme.BuildableReference {
        return XCScheme.BuildableReference(referencedContainer: "container:\(projectPath)",
                                           blueprint: pbxTarget,
                                           buildableName: target.productNameWithExtension,
                                           blueprintName: target.name,
                                           buildableIdentifier: "primary")
    }
    
    func schemeExecutionAction(action: ExecutionAction,
                               graph: Graphing,
                               generatedProjects: [AbsolutePath: GeneratedProject],
                               rootPath: AbsolutePath) throws -> XCScheme.ExecutionAction {

        guard let targetReference = action.target,
                let (target, generatedProject) = try lookupTarget(reference: targetReference,
                                                                  graph: graph,
                                                                  generatedProjects: generatedProjects,
                                                                  rootPath: rootPath) else {
                return schemeExecutionAction(action: action)
        }
        return schemeExecutionAction(action: action,
                                     target: target,
                                     generatedProject: generatedProject)
    }
    
    private func lookupTarget(reference: TargetReference,
                              graph: Graphing,
                              generatedProjects: [AbsolutePath: GeneratedProject],
                              rootPath: AbsolutePath) throws -> (Target, GeneratedProject)? {
        
        guard let projectPath = reference.projectPath else {
            return nil
        }
        
        let projectAbsolutePath = AbsolutePath(projectPath, relativeTo: rootPath)
        guard let targetNode = try graph.target(path: projectAbsolutePath, name: reference.name) else {
            return nil
        }
        
        guard let generatedProject = generatedProjects[projectAbsolutePath] else {
            return nil
        }
        
        return (targetNode.target, generatedProject)
    }
    
    func schemeExecutionAction(action: ExecutionAction) -> XCScheme.ExecutionAction {
        let schemeAction = XCScheme.ExecutionAction(scriptText: action.scriptText,
                                                    title: action.title,
                                                    environmentBuildable: nil)
        return schemeAction
    }
    
    /// Returns the scheme pre/post actions.
    ///
    /// - Parameters:
    ///   - action: pre/post action manifest.
    ///   - target: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme actions.
    func schemeExecutionAction(action: ExecutionAction,
                               target: Target,
                               generatedProject: GeneratedProject) -> XCScheme.ExecutionAction {
        /// Return Buildable Reference for Scheme Action
        func schemeBuildableReference(target: Target, generatedProject: GeneratedProject) -> XCScheme.BuildableReference? {
            guard let pbxTarget = generatedProject.targets[target.name] else { return nil }

            return targetBuildableReference(target: target, pbxTarget: pbxTarget, projectPath: generatedProject.name)
        }

        let schemeAction = XCScheme.ExecutionAction(scriptText: action.scriptText,
                                                    title: action.title,
                                                    environmentBuildable: nil)

        schemeAction.environmentBuildable = schemeBuildableReference(target: target,
                                                                     generatedProject: generatedProject)
        return schemeAction
    }
    
    /// Creates the directory where the schemes are stored inside the project.
    /// If the directory exists it does not re-create it.
    ///
    /// - Parameters:
    ///   - path: Path to the Xcode workspace or project.
    ///   - shared: Scheme should be shared or not
    /// - Returns: Path to the schemes directory.
    /// - Throws: A FatalError if the creation of the directory fails.
    private func createSchemesDirectory(path: AbsolutePath, shared: Bool = true) throws -> AbsolutePath {
        let schemePath: AbsolutePath
        if shared {
            schemePath = path.appending(RelativePath("xcshareddata/xcschemes"))
        } else {
            let username = NSUserName()
            schemePath = path.appending(RelativePath("xcuserdata/\(username).xcuserdatad/xcschemes"))
        }
        if !FileHandler.shared.exists(schemePath) {
            try FileHandler.shared.createFolder(schemePath)
        }
        return schemePath
    }
}
