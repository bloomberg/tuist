import Foundation

typealias ProjectTargetDependency = (target: String, path: String)

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
                product: .framework,
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

    private let targetDependenciesTemplate = """
                   .project(target: "{TargetDependencyTarget}", path: "{TargetDependencyPath}")
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
                  targets: [String],
                  index: Int,
                  remainingProjects: Int,
                  additionalGlobs: Int) -> String {
        projectTemplate
            .replacingOccurrences(of: "{ProjectName}", with: projectName)
            .replacingOccurrences(of: "{Targets}", with: generate(targets: targets,
                                                                  projectIndex: index,
                                                                  remainingProjects: remainingProjects,
                                                                  additionalGlobs: additionalGlobs))
    }

    private func generate(projects: [String]) -> String {
        "\n" + projects.map {
            workspaceProjectTemplate.replacingOccurrences(of: "{Project}", with: $0)
        }.joined(separator: ",\n")
    }

    private func generate(targets: [String],
                          projectIndex: Int,
                          remainingProjects: Int,
                          additionalGlobs: Int) -> String {
        "\n" + targets.map {
            targetTemplate
                .replacingOccurrences(of: "{AdditionalSourcesGlobs}", with: generate(additionalGlobs: additionalGlobs))
                .replacingOccurrences(of: "{TargetName}", with: $0)
                .replacingOccurrences(of: "{TargetDependencies}", with: generate(targetDependencies: targetDependencies(targetName: $0, projectIndex: projectIndex, remainingProjects: remainingProjects)))
        }.joined(separator: ",\n")
    }

    private func targetDependencies(targetName: String,
                                    projectIndex: Int,
                                    remainingProjects: Int) -> [ProjectTargetDependency] {
        guard generateDependencies else {
            return []
        }
        return (projectIndex + 1 ..< remainingProjects + projectIndex).map {
            (target: targetName, path: "../Project\($0 + 1)")
        }
    }

    private func generate(targetDependencies: [ProjectTargetDependency]) -> String {
        "\n" + targetDependencies.map {
            targetDependenciesTemplate
                .replacingOccurrences(of: "{TargetDependencyTarget}", with: $0.target)
                .replacingOccurrences(of: "{TargetDependencyPath}", with: $0.path)
        }.joined(separator: ",\n")
    }

    private func generate(additionalGlobs: Int) -> String {
        "\n" + (0 ..< additionalGlobs).map { _ in
            additionalSourcesGlobTemplate
        }.joined(separator: ",\n")
    }
}
