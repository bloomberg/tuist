import Foundation

typealias ProjectIndex = (index: Int, total: Int)

class ManifestTemplate {
    private let generateDependencies: Bool
    init(generateDependencies: Bool) {
        self.generateDependencies = generateDependencies
    }

    private let workspaceTemplate = """
    import ProjectDescription

    let workspace = Workspace(
        name: "{WorkspaceName}",
        projects: [
            {Projects}
        ])
    """

    private let workspaceProjectTemplate = """
          "{Project}"
    """

    private let projectTemplate = """
    import ProjectDescription

    let project = Project(
        name: "{ProjectName}",
        targets: [
            {Targets}
        ])

    """

    private let targetTemplate = """
            Target(
                name: "{TargetName}",
                platform: .iOS,
                product: {TargetProductType},
                bundleId: "io.tuist.{TargetName}",
                infoPlist: .default,
                sources: [
                    "{TargetName}/Sources/**",
                    {AdditionalSourcesGlobs}
                ],
                resources: [
                    "{TargetName}/Resources/**",
                ],
                headers: Headers(
                    public: "{TargetName}/Sources/Public/**", 
                    private: "{TargetName}/Sources/Private/**", 
                    project: "{TargetName}/Sources/Project/**"
                ),
                dependencies: [
                   {TargetDependencies}
            ])
    """

    private let targetProjectDependenciesTemplate = """
                   .project(target: "{TargetDependencyTarget}", path: "{TargetDependencyPath}")
    """

    private let targetDependenciesTemplate = """
                    .target(name: "{TargetDependencyTarget}")
    """

    private let additionalSourcesGlobTemplate = """
                    "{TargetName}/Sources/**/*"
    """

    func generate(workspaceName: String, projects: [String]) -> String {
        workspaceTemplate
            .replacingOccurrences(of: "{WorkspaceName}", with: workspaceName)
            .replacingOccurrences(of: "{Projects}", with: generate(projects: projects))
    }

    func generate(projectName: String,
                  appTargets: [String],
                  targets: [String],
                  testTargets: [String],
                  projectIndex: ProjectIndex,
                  additionalGlobs: Int) -> String {
        projectTemplate
            .replacingOccurrences(of: "{ProjectName}", with: projectName)
            .replacingOccurrences(of: "{Targets}", with: generate(appTargets: appTargets,
                                                                  targets: targets,
                                                                  testTargets: testTargets,
                                                                  projectIndex: projectIndex,
                                                                  additionalGlobs: additionalGlobs))
    }

    private func generate(projects: [String]) -> String {
        "\n" + projects.map {
            workspaceProjectTemplate.replacingOccurrences(of: "{Project}", with: $0)
        }.joined(separator: ",\n")
    }

    private func generate(appTargets: [String],
                          targets: [String],
                          testTargets: [String],
                          projectIndex: ProjectIndex,
                          additionalGlobs: Int) -> String {
        let frameworkTargets = targets.map {
            genertate(target: $0,
                      product: ".framework",
                      additionalGlobs: additionalGlobs,
                      targetDependencies: targetProjectDependencies(targetName: $0,
                                                                    projectIndex: projectIndex))
        }

        let appTargets = appTargets.map {
            genertate(target: $0,
                      product: ".app",
                      additionalGlobs: additionalGlobs,
                      targetDependencies: targetDependencies(dependenctTargets: targets))
        }

        let testTargets = testTargets.map {
            genertate(target: $0,
                      product: ".unitTests",
                      additionalGlobs: additionalGlobs,
                      targetDependencies: targetDependencies(dependenctTargets: targets))
        }

        return "\n" +
            (appTargets + frameworkTargets + testTargets)
            .joined(separator: ",\n")
    }

    private func genertate(target: String,
                           product: String,
                           additionalGlobs: Int,
                           targetDependencies: [String]) -> String {
        targetTemplate
            .replacingOccurrences(of: "{TargetName}", with: target)
            .replacingOccurrences(of: "{TargetProductType}", with: product)
            .replacingOccurrences(of: "{AdditionalSourcesGlobs}", with: generate(additionalGlobs: additionalGlobs))
            .replacingOccurrences(of: "{TargetDependencies}", with: generate(targetDependencies: targetDependencies))
    }

    private func targetProjectDependencies(targetName: String,
                                           projectIndex: ProjectIndex) -> [String] {
        guard generateDependencies else {
            return []
        }
        return (projectIndex.index + 1 ..< projectIndex.total).map {
            targetProjectDependenciesTemplate
                .replacingOccurrences(of: "{TargetDependencyTarget}", with: targetName)
                .replacingOccurrences(of: "{TargetDependencyPath}", with: "../Project\($0 + 1)")
        }
    }

    private func targetDependencies(dependenctTargets: [String]) -> [String] {
        dependenctTargets.map {
            targetDependenciesTemplate
                .replacingOccurrences(of: "{TargetDependencyTarget}", with: $0)
        }
    }

    private func generate(targetDependencies: [String]) -> String {
        "\n" + targetDependencies.joined(separator: ",\n")
    }

    private func generate(additionalGlobs: Int) -> String {
        "\n" + (0 ..< additionalGlobs).map { _ in
            additionalSourcesGlobTemplate
        }.joined(separator: ",\n")
    }
}
