import Foundation

class ManifestTemplate {
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
            ])
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
                  additionalGlobs: Int) -> String {
        projectTemplate
            .replacingOccurrences(of: "{ProjectName}", with: projectName)
            .replacingOccurrences(of: "{Targets}", with: generate(targets: targets, additionalGlobs: additionalGlobs))
    }

    private func generate(projects: [String]) -> String {
        "\n" + projects.map {
            workspaceProjectTemplate.replacingOccurrences(of: "{Project}", with: $0)
        }.joined(separator: ",\n")
    }

    private func generate(targets: [String], additionalGlobs: Int) -> String {
        "\n" + targets.map {
            targetTemplate
                .replacingOccurrences(of: "{AdditionalSourcesGlobs}", with: generate(additionalGlobs: additionalGlobs))
                .replacingOccurrences(of: "{TargetName}", with: $0)
        }.joined(separator: ",\n")
    }

    private func generate(additionalGlobs: Int) -> String {
        "\n" + (0 ..< additionalGlobs).map { _ in
            additionalSourcesGlobTemplate
        }.joined(separator: ",\n")
    }
}
