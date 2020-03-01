import Foundation
import TSCBasic
import TSCUtility

enum GenerateCommandError: Error {
    case invalidPath
}

final class GenerateCommand {
    private let pathArgument: OptionArgument<String>
    private let projectsArgument: OptionArgument<Int>
    private let targetsArgument: OptionArgument<Int>
    private let sourcesArgument: OptionArgument<Int>
    private let headersArgument: OptionArgument<Int>
    private let resourcesArgument: OptionArgument<Int>
    private let globsArgument: OptionArgument<Int>

    private let fileSystem: FileSystem

    init(fileSystem: FileSystem,
         parser: ArgumentParser) {
        self.fileSystem = fileSystem

        pathArgument = parser.add(option: "--path",
                                  kind: String.self,
                                  usage: "The path where the fixture will be generated.",
                                  completion: .filename)
        projectsArgument = parser.add(option: "--projects",
                                      shortName: "-p",
                                      kind: Int.self,
                                      usage: "Number of projects to generate.")
        targetsArgument = parser.add(option: "--targets",
                                     shortName: "-t",
                                     kind: Int.self,
                                     usage: "Number of targets to generate within each project.")
        sourcesArgument = parser.add(option: "--sources",
                                     shortName: "-s",
                                     kind: Int.self,
                                     usage: "Number of sources to generate within each target.")
        headersArgument = parser.add(option: "--headers",
                                     shortName: "-h",
                                     kind: Int.self,
                                     usage: "Number of headers to generate within each target.")
        resourcesArgument = parser.add(option: "--resources",
                                       shortName: "-r",
                                       kind: Int.self,
                                       usage: "Number of resources to generate within each target.")
        globsArgument = parser.add(option: "--globs",
                                   shortName: "-g",
                                   kind: Int.self,
                                   usage: "Number of additional glob patterns to include within manifes.")
    }

    func run(with arguments: ArgumentParser.Result) throws {
        let defaultConfig = GeneratorConfig.default

        let path = try determineFixturePath(using: arguments)
        let projects = arguments.get(projectsArgument) ?? defaultConfig.projects
        let targets = arguments.get(targetsArgument) ?? defaultConfig.targets
        let sources = arguments.get(sourcesArgument) ?? defaultConfig.sources
        let headers = arguments.get(headersArgument) ?? defaultConfig.headers
        let resources = arguments.get(resourcesArgument) ?? defaultConfig.resources
        let additionalGlobs = arguments.get(globsArgument) ?? defaultConfig.additionalGlobs

        let config = GeneratorConfig(projects: projects,
                                     targets: targets,
                                     sources: sources,
                                     headers: headers,
                                     resources: resources,
                                     additionalGlobs: additionalGlobs)
        let generator = Generator(fileSystem: fileSystem, config: config)

        try generator.generate(at: path)
    }

    private func determineFixturePath(using arguments: ArgumentParser.Result) throws -> AbsolutePath {
        guard let currentPath = fileSystem.currentWorkingDirectory else {
            throw GenerateCommandError.invalidPath
        }

        guard let path = arguments.get(pathArgument) else {
            return currentPath
        }
        return AbsolutePath(path, relativeTo: currentPath)
    }
}
