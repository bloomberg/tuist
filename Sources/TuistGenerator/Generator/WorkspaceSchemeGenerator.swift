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
    
    private var schemeGeneratorHelpers: SchemeGeneratorHelpers
    
    public init(schemeGeneratorHelpers: SchemeGeneratorHelpers = SchemeGeneratorHelpers()) {
        self.schemeGeneratorHelpers = schemeGeneratorHelpers
    }
    
    func generateWorkspaceSchemes(workspace: Workspace, xcworkspacePath: AbsolutePath, generatedProjects: [AbsolutePath : GeneratedProject], graph: Graphing) throws {
        try workspace.schemes.forEach { scheme in
            try generateScheme(scheme: scheme, xcworkspacePath: xcworkspacePath, workspacePath: workspace.path, graph: graph, generatedProjects: generatedProjects)
        }
    }
    
    // Generates the schemes for a workspace.
    private func generateScheme(scheme: Scheme,
                                xcworkspacePath: AbsolutePath,
                                workspacePath: AbsolutePath,
                                graph: Graphing,
                                generatedProjects: [AbsolutePath: GeneratedProject]) throws {
        let schemeDirectory = try schemeGeneratorHelpers.createSchemesDirectory(path: xcworkspacePath, shared: scheme.shared)
        let schemePath = schemeDirectory.appending(component: "\(scheme.name).xcscheme")
        let generatedBuildAction = try schemeBuildAction(scheme: scheme,
                                                         graph: graph,
                                                         rootPath: workspacePath,
                                                         generatedProjects: generatedProjects)
        let generatedTestAction = try schemeTestAction(scheme: scheme,
                                                       graph: graph,
                                                       rootPath: workspacePath,
                                                       generatedProjects: generatedProjects)
        let generatedLaunchAction = try schemeLaunchAction(scheme: scheme,
                                                           graph: graph,
                                                           rootPath: workspacePath,
                                                           generatedProjects: generatedProjects)
        let generatedProfileAction = try schemeProfileAction(scheme: scheme,
                                                             graph: graph,
                                                             rootPath: workspacePath,
                                                             generatedProjects: generatedProjects)
        
        let scheme = XCScheme(name: scheme.name,
                              lastUpgradeVersion: WorkspaceSchemesGenerator.defaultLastUpgradeVersion,
                              version: WorkspaceSchemesGenerator.defaultVersion,
                              buildAction: generatedBuildAction,
                              testAction: generatedTestAction,
                              launchAction: generatedLaunchAction,
                              profileAction: generatedProfileAction)
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
    private func schemeBuildAction(scheme: Scheme,
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
            
            let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: target.target,
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
    
    private func schemeTestAction(scheme: Scheme,
                          graph: Graphing,
                          rootPath: AbsolutePath,
                          generatedProjects: [AbsolutePath: GeneratedProject]) throws -> XCScheme.TestAction? {
        guard let testAction = scheme.testAction else { return nil }
        
        var testables: [XCScheme.TestableReference] = []
        var preActions: [XCScheme.ExecutionAction] = []
        var postActions: [XCScheme.ExecutionAction] = []

        try testAction.targets.forEach { testActionTarget in
            guard let projectPath = testActionTarget.projectPath else { return }
            let pathToProject = rootPath.appending(RelativePath(projectPath))
            guard let target = try graph.target(path: pathToProject,
                                                name: testActionTarget.name) else { return }
            guard let generatedProject = generatedProjects[pathToProject] else { return }
            guard let pbxTarget = generatedProject.targets[testActionTarget.name] else { return }
            let relativeXcodeProjectPath = generatedProject.path.relative(to: rootPath)
            
            let reference = schemeGeneratorHelpers.targetBuildableReference(target: target.target,
                                                                            pbxTarget: pbxTarget,
                                                                            projectPath: relativeXcodeProjectPath.pathString)

            let testable = XCScheme.TestableReference(skipped: false, buildableReference: reference)
            testables.append(testable)
        }
        
        preActions = try testAction.preActions.map {
            try schemeExecutionAction(action: $0, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath)
        }
        
        postActions = try testAction.postActions.map {
            try schemeExecutionAction(action: $0, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath)
        }

        var args: XCScheme.CommandLineArguments?
        var environments: [XCScheme.EnvironmentVariable]?

        if let arguments = testAction.arguments {
            args = XCScheme.CommandLineArguments(arguments: schemeGeneratorHelpers.commandlineArgruments(arguments.launch))
            environments = schemeGeneratorHelpers.environmentVariables(arguments.environment)
        }
        
        let codeCoverageTargets = try testAction.targets.compactMap {
            try testCoverageTargetReferences(target: $0, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath)
        }

        let onlyGenerateCoverageForSpecifiedTargets = codeCoverageTargets.count > 0 ? true : nil

        let shouldUseLaunchSchemeArgsEnv: Bool = args == nil && environments == nil

        return XCScheme.TestAction(buildConfiguration: testAction.configurationName,
                                   macroExpansion: nil,
                                   testables: testables,
                                   preActions: preActions,
                                   postActions: postActions,
                                   shouldUseLaunchSchemeArgsEnv: shouldUseLaunchSchemeArgsEnv,
                                   codeCoverageEnabled: testAction.coverage,
                                   codeCoverageTargets: codeCoverageTargets,
                                   onlyGenerateCoverageForSpecifiedTargets: onlyGenerateCoverageForSpecifiedTargets,
                                   commandlineArguments: args,
                                   environmentVariables: environments)
    }
    
    private func schemeLaunchAction(scheme: Scheme,
                            graph: Graphing,
                            rootPath: AbsolutePath,
                            generatedProjects: [AbsolutePath: GeneratedProject]) throws -> XCScheme.LaunchAction? {
        
        guard let executable = scheme.runAction?.executable,
            let (targetNode, generatedProject) = try lookupTarget(reference: executable, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath) else {
                return nil
        }
        
        guard let pbxTarget = generatedProject.targets[targetNode.target.name] else { return nil }

        var buildableProductRunnable: XCScheme.BuildableProductRunnable?
        var macroExpansion: XCScheme.BuildableReference?
        let relativeXcodeProjectPath = generatedProject.path.relative(to: rootPath)
        let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: targetNode.target, pbxTarget: pbxTarget, projectPath: relativeXcodeProjectPath.pathString)
        if targetNode.target.product.runnable {
            buildableProductRunnable = XCScheme.BuildableProductRunnable(buildableReference: buildableReference, runnableDebuggingMode: "0")
        } else {
            macroExpansion = buildableReference
        }

        var commandlineArguments: XCScheme.CommandLineArguments?
        var environments: [XCScheme.EnvironmentVariable]?

        if let arguments = scheme.runAction?.arguments {
            commandlineArguments = XCScheme.CommandLineArguments(arguments: schemeGeneratorHelpers.commandlineArgruments(arguments.launch))
            environments = schemeGeneratorHelpers.environmentVariables(arguments.environment)
        }

        let buildConfiguration = scheme.runAction?.configurationName ?? schemeGeneratorHelpers.defaultDebugBuildConfigurationName(in: targetNode.project)
        return XCScheme.LaunchAction(runnable: buildableProductRunnable,
                                     buildConfiguration: buildConfiguration,
                                     macroExpansion: macroExpansion,
                                     commandlineArguments: commandlineArguments,
                                     environmentVariables: environments)
    }
    
    private func schemeProfileAction(scheme: Scheme,
                             graph: Graphing,
                             rootPath: AbsolutePath,
                             generatedProjects: [AbsolutePath: GeneratedProject]) throws -> XCScheme.ProfileAction? {
        
        guard let executable = scheme.runAction?.executable,
            let (targetNode, generatedProject) = try lookupTarget(reference: executable, graph: graph, generatedProjects: generatedProjects, rootPath: rootPath) else {
            return nil
        }

        guard let pbxTarget = generatedProject.targets[targetNode.target.name] else { return nil }

        var buildableProductRunnable: XCScheme.BuildableProductRunnable?
        var macroExpansion: XCScheme.BuildableReference?
        let relativeXcodeProjectPath = generatedProject.path.relative(to: rootPath)
        let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: targetNode.target, pbxTarget: pbxTarget, projectPath: relativeXcodeProjectPath.pathString)

        if targetNode.target.product.runnable {
            buildableProductRunnable = XCScheme.BuildableProductRunnable(buildableReference: buildableReference, runnableDebuggingMode: "0")
        } else {
            macroExpansion = buildableReference
        }

        let buildConfiguration = schemeGeneratorHelpers.defaultReleaseBuildConfigurationName(in: targetNode.project)
        return XCScheme.ProfileAction(buildableProductRunnable: buildableProductRunnable,
                                      buildConfiguration: buildConfiguration,
                                      macroExpansion: macroExpansion)
    }
    
    private func schemeExecutionAction(action: ExecutionAction,
                               graph: Graphing,
                               generatedProjects: [AbsolutePath: GeneratedProject],
                               rootPath: AbsolutePath) throws -> XCScheme.ExecutionAction {

        guard let targetReference = action.target,
                let (targetNode, generatedProject) = try lookupTarget(reference: targetReference,
                                                                  graph: graph,
                                                                  generatedProjects: generatedProjects,
                                                                  rootPath: rootPath) else {
                return schemeExecutionAction(action: action)
        }
        return schemeExecutionAction(action: action,
                                     target: targetNode.target,
                                     generatedProject: generatedProject)
    }
    
    private func lookupTarget(reference: TargetReference,
                              graph: Graphing,
                              generatedProjects: [AbsolutePath: GeneratedProject],
                              rootPath: AbsolutePath) throws -> (TargetNode, GeneratedProject)? {
        
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
        
        return (targetNode, generatedProject)
    }
    
    private func schemeExecutionAction(action: ExecutionAction) -> XCScheme.ExecutionAction {
        return XCScheme.ExecutionAction(scriptText: action.scriptText,
                                        title: action.title,
                                        environmentBuildable: nil)
    }
    
    /// Returns the scheme pre/post actions.
    ///
    /// - Parameters:
    ///   - action: pre/post action manifest.
    ///   - target: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme actions.
    private func schemeExecutionAction(action: ExecutionAction,
                               target: Target,
                               generatedProject: GeneratedProject) -> XCScheme.ExecutionAction {
        /// Return Buildable Reference for Scheme Action
        func schemeBuildableReference(target: Target, generatedProject: GeneratedProject) -> XCScheme.BuildableReference? {
            guard let pbxTarget = generatedProject.targets[target.name] else { return nil }
            
            return schemeGeneratorHelpers.targetBuildableReference(target: target, pbxTarget: pbxTarget, projectPath: generatedProject.name)
        }

        let schemeAction = XCScheme.ExecutionAction(scriptText: action.scriptText,
                                                    title: action.title,
                                                    environmentBuildable: nil)

        schemeAction.environmentBuildable = schemeBuildableReference(target: target,
                                                                     generatedProject: generatedProject)
        return schemeAction
    }
    
    private func testCoverageTargetReferences(target: TargetReference,
                                              graph: Graphing,
                                              generatedProjects: [AbsolutePath: GeneratedProject],
                                              rootPath: AbsolutePath) throws -> XCScheme.BuildableReference? {
        guard let (targetNode, generatedProject) = try lookupTarget(reference: target,
                                                                graph: graph,
                                                                generatedProjects: generatedProjects,
                                                                rootPath: rootPath) else {
            return nil
        }
        
        guard let pbxTarget = generatedProject.targets[targetNode.target.name] else { return nil }

        return schemeGeneratorHelpers.targetBuildableReference(target: targetNode.target,
                                                               pbxTarget: pbxTarget,
                                                               projectPath: generatedProject.name)
    }
}
