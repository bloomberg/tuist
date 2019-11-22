import Basic
import Foundation
import TuistCore
import TuistSupport
import XcodeProj

/// Protocol that defines the interface of the schemes generation.
protocol SchemesGenerating {
    /// Generates the schemes for the project targets.
    ///
    /// - Parameters:
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Throws: A FatalError if the generation of the schemes fails.
    func generateProjectSchemes(project: Project,
                               generatedProject: GeneratedProject,
                               graph: Graphing) throws
}

// swiftlint:disable:next type_body_length
final class SchemesGenerator: SchemesGenerating {
    /// Default last upgrade version for generated schemes.
    private static let defaultLastUpgradeVersion = "1010"

    /// Default version for generated schemes.
    private static let defaultVersion = "1.3"
    
    private var schemeGeneratorHelpers: SchemeGeneratorHelpers
    
    init(schemeGeneratorHelpers: SchemeGeneratorHelpers = SchemeGeneratorHelpers()) {
        self.schemeGeneratorHelpers = schemeGeneratorHelpers
    }

    /// Generates the schemes for the project manifest.
    ///
    /// - Parameters:
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Throws: A FatalError if the generation of the schemes fails.
    func generateProjectSchemes(project: Project, generatedProject: GeneratedProject, graph: Graphing) throws {
        /// Generate scheme from manifest
        try project.schemes.forEach { scheme in
            try generateScheme(scheme: scheme, project: project, generatedProject: generatedProject)
        }

        /// Generate scheme for every targets in Project that is not defined in Manifest
        let buildConfiguration = schemeGeneratorHelpers.defaultDebugBuildConfigurationName(in: project)
        try project.targets.forEach { target in

            if !project.schemes.contains(where: { $0.name == target.name }) {
                let scheme = Scheme(name: target.name,
                                    shared: true,
                                    buildAction: BuildAction(targets: [.project(path: project.path, target: target.name)]),
                                    testAction: TestAction(targets: [.project(path: project.path, target: target.name)], configurationName: buildConfiguration),
                                    runAction: RunAction(configurationName: buildConfiguration,
                                                         executable: .project(path: project.path, target: target.name),
                                                         arguments: Arguments(environment: target.environment)))

                try generateScheme(scheme: scheme,
                                   project: project,
                                   generatedProject: generatedProject)
            }
        }
    }

    /// Generates the scheme for a project.
    ///
    /// - Parameters:
    ///   - scheme: Scheme manifest.
    ///   - project: Project manifest.
    ///   - generatedProjects: Generated Xcode project.
    /// - Throws: An error if the generation fails.
    private func generateScheme(scheme: Scheme,
                                project: Project,
                                generatedProject: GeneratedProject) throws {
        let schemesDirectory = try schemeGeneratorHelpers.createSchemesDirectory(path: generatedProject.path, shared: scheme.shared)
        let schemePath = schemesDirectory.appending(component: "\(scheme.name).xcscheme")
        
        let generatedBuildAction = try schemeBuildAction(scheme: scheme, project: project, generatedProject: generatedProject)
        let generatedTestAction = schemeTestAction(scheme: scheme, project: project, generatedProject: generatedProject)
        let generatedLaunchAction = schemeLaunchAction(scheme: scheme, project: project, generatedProject: generatedProject)
        let generatedProfileAction = schemeProfileAction(scheme: scheme, project: project, generatedProject: generatedProject)

        let scheme = XCScheme(name: scheme.name,
                              lastUpgradeVersion: SchemesGenerator.defaultLastUpgradeVersion,
                              version: SchemesGenerator.defaultVersion,
                              buildAction: generatedBuildAction,
                              testAction: generatedTestAction,
                              launchAction: generatedLaunchAction,
                              profileAction: generatedProfileAction,
                              analyzeAction: schemeAnalyzeAction(for: project),
                              archiveAction: schemeArchiveAction(for: project))
        try scheme.write(path: schemePath.path, override: true)
    }
// not used
//    /// Returns the build action for the project scheme.
//    ///
//    /// - Parameters:
//    ///   - project: Project manifest.
//    ///   - generatedProject: Generated Xcode project.
//    ///   - graph: Dependencies graph.
//    /// - Returns: Scheme build action.
//    func projectBuildAction(project: Project,
//                            generatedProject: GeneratedProject,
//                            graph: Graphing) -> XCScheme.BuildAction {
//        let targets = project.sortedTargetsForProjectScheme(graph: graph)
//        let entries: [XCScheme.BuildAction.Entry] = targets.map { (target) -> XCScheme.BuildAction.Entry in
//
//            let pbxTarget = generatedProject.targets[target.name]!
//            let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: target,
//                                                                                     pbxTarget: pbxTarget,
//                                                                                     projectPath: generatedProject.name)
//            var buildFor: [XCScheme.BuildAction.Entry.BuildFor] = []
//            if target.product.testsBundle {
//                buildFor.append(.testing)
//            } else {
//                buildFor.append(contentsOf: [.analyzing, .archiving, .profiling, .running, .testing])
//            }
//
//            return XCScheme.BuildAction.Entry(buildableReference: buildableReference,
//                                              buildFor: buildFor)
//        }
//
//        return XCScheme.BuildAction(buildActionEntries: entries,
//                                    parallelizeBuild: true,
//                                    buildImplicitDependencies: true)
//    }

// not used
//    /// Generates the test action for the project scheme.
//    ///
//    /// - Parameters:
//    ///   - project: Project manifest.
//    ///   - generatedProject: Generated Xcode project.
//    /// - Returns: Scheme test action.
//    func projectTestAction(project: Project,
//                           generatedProject: GeneratedProject) -> XCScheme.TestAction {
//        var testables: [XCScheme.TestableReference] = []
//        let testTargets = project.targets.filter { $0.product.testsBundle }
//
//        testTargets.forEach { target in
//            let pbxTarget = generatedProject.targets[target.name]!
//
//            let reference = schemeGeneratorHelpers.targetBuildableReference(target: target,
//                                                                            pbxTarget: pbxTarget,
//                                                                            projectPath: generatedProject.name)
//            let testable = XCScheme.TestableReference(skipped: false,
//                                                      buildableReference: reference)
//            testables.append(testable)
//        }
//
//        let buildConfiguration = schemeGeneratorHelpers.defaultDebugBuildConfigurationName(in: project)
//        return XCScheme.TestAction(buildConfiguration: buildConfiguration,
//                                   macroExpansion: nil,
//                                   testables: testables)
//    }

    /// Generates the array of BuildableReference for targets that the
    /// coverage report should be generated for them.
    ///
    /// - Parameters:
    ///   - testAction: test actions.
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Array of buildable references.
    private func testCoverageTargetReferences(testAction: TestAction, project: Project, generatedProject: GeneratedProject) -> [XCScheme.BuildableReference] {
        var codeCoverageTargets: [XCScheme.BuildableReference] = []
        testAction.codeCoverageTargets.forEach { reference in
            guard let target = project.targets.first(where: { $0.name == reference.name }) else { return }
            guard let pbxTarget = generatedProject.targets[reference.name] else { return }
            
            let reference = schemeGeneratorHelpers.targetBuildableReference(target: target,
                                                                            pbxTarget: pbxTarget,
                                                                            projectPath: generatedProject.name)
            codeCoverageTargets.append(reference)
        }

        return codeCoverageTargets
    }

    /// Generates the scheme test action.
    ///
    /// - Parameters:
    ///   - scheme: Scheme manifest.
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme test action.
    func schemeTestAction(scheme: Scheme,
                          project: Project,
                          generatedProject: GeneratedProject) -> XCScheme.TestAction? {
        guard let testAction = scheme.testAction else { return nil }

        var testables: [XCScheme.TestableReference] = []
        var preActions: [XCScheme.ExecutionAction] = []
        var postActions: [XCScheme.ExecutionAction] = []

        testAction.targets.forEach { targetReference in
            guard let target = project.targets.first(where: { $0.name == targetReference.name }), target.product.testsBundle else { return }
            guard let pbxTarget = generatedProject.targets[targetReference.name] else { return }
            
            let reference = schemeGeneratorHelpers.targetBuildableReference(target: target,
                                                                            pbxTarget: pbxTarget,
                                                                            projectPath: generatedProject.name)
            
            let testable = XCScheme.TestableReference(skipped: false, buildableReference: reference)
            testables.append(testable)
        }

        preActions = schemeExecutionActions(actions: testAction.preActions,
                                            project: project,
                                            generatedProject: generatedProject)

        postActions = schemeExecutionActions(actions: testAction.postActions,
                                             project: project,
                                             generatedProject: generatedProject)

        var args: XCScheme.CommandLineArguments?
        var environments: [XCScheme.EnvironmentVariable]?

        if let arguments = testAction.arguments {
            args = XCScheme.CommandLineArguments(arguments: schemeGeneratorHelpers.commandlineArgruments(arguments.launch))
            environments = schemeGeneratorHelpers.environmentVariables(arguments.environment)
        }

        let codeCoverageTargets = testCoverageTargetReferences(testAction: testAction, project: project, generatedProject: generatedProject)

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

    /// Generates the scheme build action.
    ///
    /// - Parameters:
    ///   - scheme: Scheme manifest.
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme build action.
    func schemeBuildAction(scheme: Scheme,
                           project: Project,
                           generatedProject: GeneratedProject) throws -> XCScheme.BuildAction? {
        guard let buildAction = scheme.buildAction else { return nil }

        let buildFor: [XCScheme.BuildAction.Entry.BuildFor] = [
            .analyzing, .archiving, .profiling, .running, .testing,
        ]

        var entries: [XCScheme.BuildAction.Entry] = []
        var preActions: [XCScheme.ExecutionAction] = []
        var postActions: [XCScheme.ExecutionAction] = []

        buildAction.targets.forEach { buildActionTarget in
            guard let target = project.targets.first(where: { $0.name == buildActionTarget.name }) else { return }
        
            guard let pbxTarget = generatedProject.targets[buildActionTarget.name] else { return }
            let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: target,
                                                                                     pbxTarget: pbxTarget,
                                                                                     projectPath: generatedProject.name)

            entries.append(XCScheme.BuildAction.Entry(buildableReference: buildableReference, buildFor: buildFor))
        }

        preActions = schemeExecutionActions(actions: buildAction.preActions,
                                            project: project,
                                            generatedProject: generatedProject)

        postActions = schemeExecutionActions(actions: buildAction.postActions,
                                             project: project,
                                             generatedProject: generatedProject)

        return XCScheme.BuildAction(buildActionEntries: entries,
                                    preActions: preActions,
                                    postActions: postActions,
                                    parallelizeBuild: true,
                                    buildImplicitDependencies: true)
    }

    /// Generates the scheme launch action.
    ///
    /// - Parameters:
    ///   - scheme: Scheme manifest.
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme launch action.
    func schemeLaunchAction(scheme: Scheme,
                            project: Project,
                            generatedProject: GeneratedProject) -> XCScheme.LaunchAction? {
        guard var target = project.targets.first(where: { $0.name == scheme.buildAction?.targets.first?.name }) else { return nil }

        if let executable = scheme.runAction?.executable {
            guard let runableTarget = project.targets.first(where: { $0.name == executable.name }) else { return nil }
            target = runableTarget
        }

        guard let pbxTarget = generatedProject.targets[target.name] else { return nil }

        var buildableProductRunnable: XCScheme.BuildableProductRunnable?
        var macroExpansion: XCScheme.BuildableReference?
        let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: target, pbxTarget: pbxTarget, projectPath: generatedProject.name)
        if target.product.runnable {
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

        let buildConfiguration = scheme.runAction?.configurationName ?? schemeGeneratorHelpers.defaultDebugBuildConfigurationName(in: project)
        return XCScheme.LaunchAction(runnable: buildableProductRunnable,
                                     buildConfiguration: buildConfiguration,
                                     macroExpansion: macroExpansion,
                                     commandlineArguments: commandlineArguments,
                                     environmentVariables: environments)
    }

    /// Generates the scheme profile action for a given target.
    ///
    /// - Parameters:
    ///   - target: Target manifest.
    ///   - pbxTarget: Xcode native target.
    ///   - projectName: Project name with .xcodeproj extension.
    /// - Returns: Scheme profile action.
    func schemeProfileAction(scheme: Scheme,
                                     project: Project,
                                     generatedProject: GeneratedProject) -> XCScheme.ProfileAction? {
        
        guard var target = project.targets.first(where: { $0.name == scheme.buildAction?.targets.first?.name }) else { return nil }

        if let executable = scheme.runAction?.executable {
            guard let runableTarget = project.targets.first(where: { $0.name == executable.name }) else { return nil }
            target = runableTarget
        }

        guard let pbxTarget = generatedProject.targets[target.name] else { return nil }

        var buildableProductRunnable: XCScheme.BuildableProductRunnable?
        var macroExpansion: XCScheme.BuildableReference?
        let buildableReference = schemeGeneratorHelpers.targetBuildableReference(target: target, pbxTarget: pbxTarget, projectPath: generatedProject.name)

        if target.product.runnable {
            buildableProductRunnable = XCScheme.BuildableProductRunnable(buildableReference: buildableReference, runnableDebuggingMode: "0")
        } else {
            macroExpansion = buildableReference
        }

        let buildConfiguration = schemeGeneratorHelpers.defaultReleaseBuildConfigurationName(in: project)
        return XCScheme.ProfileAction(buildableProductRunnable: buildableProductRunnable,
                                      buildConfiguration: buildConfiguration,
                                      macroExpansion: macroExpansion)
    }

    /// Returns the scheme pre/post actions.
    ///
    /// - Parameters:
    ///   - actions: pre/post action manifest.
    ///   - project: Project manifest.
    ///   - generatedProject: Generated Xcode project.
    /// - Returns: Scheme actions.
    private func schemeExecutionActions(actions: [ExecutionAction],
                                        project: Project,
                                        generatedProject: GeneratedProject) -> [XCScheme.ExecutionAction] {
        /// Return Buildable Reference for Scheme Action
        func schemeBuildableReference(targetName: String?, project: Project, generatedProject: GeneratedProject) -> XCScheme.BuildableReference? {
            guard let targetName = targetName else { return nil }
            guard let target = project.targets.first(where: { $0.name == targetName }) else { return nil }
            guard let pbxTarget = generatedProject.targets[targetName] else { return nil }

            return schemeGeneratorHelpers.targetBuildableReference(target: target, pbxTarget: pbxTarget, projectPath: generatedProject.name)
        }

        var schemeActions: [XCScheme.ExecutionAction] = []
        actions.forEach { action in
            let schemeAction = XCScheme.ExecutionAction(scriptText: action.scriptText,
                                                        title: action.title,
                                                        environmentBuildable: nil)

            schemeAction.environmentBuildable = schemeBuildableReference(targetName: action.target?.name,
                                                                         project: project,
                                                                         generatedProject: generatedProject)
            schemeActions.append(schemeAction)
        }
        return schemeActions
    }
    
    /// Returns the scheme analyze action
    ///
    /// - Returns: Scheme analyze action.
    func schemeAnalyzeAction(for project: Project) -> XCScheme.AnalyzeAction {
        let buildConfiguration = schemeGeneratorHelpers.defaultDebugBuildConfigurationName(in: project)
        return XCScheme.AnalyzeAction(buildConfiguration: buildConfiguration)
    }

    /// Returns the scheme archive action
    ///
    /// - Returns: Scheme archive action.
    func schemeArchiveAction(for project: Project) -> XCScheme.ArchiveAction {
        let buildConfiguration = schemeGeneratorHelpers.defaultReleaseBuildConfigurationName(in: project)
        return XCScheme.ArchiveAction(buildConfiguration: buildConfiguration,
                                      revealArchiveInOrganizer: true)
    }
}
