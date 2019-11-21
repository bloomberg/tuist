import Foundation
import Basic
import TuistCore
import TuistSupport
import XcodeProj


final class SchemeGeneratorHelpers {
    /// Creates the directory where the schemes are stored inside the project.
    /// If the directory exists it does not re-create it.
    ///
    /// - Parameters:
    ///   - path: Path to the Xcode workspace or project.
    ///   - shared: Scheme should be shared or not
    /// - Returns: Path to the schemes directory.
    /// - Throws: A FatalError if the creation of the directory fails.
    func createSchemesDirectory(path: AbsolutePath, shared: Bool = true) throws -> AbsolutePath {
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
    
    /// Returns the scheme commandline argument passed on launch
    ///
    /// - Parameters:
    /// - environments: commandline argument keys.
    /// - Returns: XCScheme.CommandLineArguments.CommandLineArgument.
    func commandlineArgruments(_ arguments: [String: Bool]) -> [XCScheme.CommandLineArguments.CommandLineArgument] {
        return arguments.map { key, enabled in
            XCScheme.CommandLineArguments.CommandLineArgument(name: key, enabled: enabled)
        }
    }
    
    /// Returns the scheme environment variables
    ///
    /// - Parameters:
    /// - environments: environment variables
    /// - Returns: XCScheme.EnvironmentVariable.
    func environmentVariables(_ environments: [String: String]) -> [XCScheme.EnvironmentVariable] {
        return environments.map { key, value in
            XCScheme.EnvironmentVariable(variable: key, value: value, enabled: true)
        }
    }
    
    func defaultDebugBuildConfigurationName(in project: Project) -> String {
        let debugConfiguration = project.settings.defaultDebugBuildConfiguration()
        let buildConfiguration = debugConfiguration ?? project.settings.configurations.keys.first

        return buildConfiguration?.name ?? BuildConfiguration.debug.name
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
    
    func defaultReleaseBuildConfigurationName(in project: Project) -> String {
        let releaseConfiguration = project.settings.defaultReleaseBuildConfiguration()
        let buildConfiguration = releaseConfiguration ?? project.settings.configurations.keys.first

        return buildConfiguration?.name ?? BuildConfiguration.release.name
    }
    
    /// Returns the scheme analyze action
    ///
    /// - Returns: Scheme analyze action.
    func schemeAnalyzeAction(for project: Project) -> XCScheme.AnalyzeAction {
        let buildConfiguration = defaultDebugBuildConfigurationName(in: project)
        return XCScheme.AnalyzeAction(buildConfiguration: buildConfiguration)
    }

    /// Returns the scheme archive action
    ///
    /// - Returns: Scheme archive action.
    func schemeArchiveAction(for project: Project) -> XCScheme.ArchiveAction {
        let buildConfiguration = defaultReleaseBuildConfigurationName(in: project)
        return XCScheme.ArchiveAction(buildConfiguration: buildConfiguration,
                                      revealArchiveInOrganizer: true)
    }
}
