import Basic
import Foundation
import TuistCore

protocol SettingsLinting: AnyObject {
    func lint(project: Project) -> [LintingIssue]
    func lint(target: Target) -> [LintingIssue]
}

final class SettingsLinter: SettingsLinting {
    // MARK: - Attributes

    let fileHandler: FileHandling

    // MARK: - Init

    init(fileHandler: FileHandling = FileHandler()) {
        self.fileHandler = fileHandler
    }

    // MARK: - SettingsLinting

    func lint(project: Project) -> [LintingIssue] {
        var issues: [LintingIssue] = []
        issues.append(contentsOf: lintConfigFilesExist(settings: project.settings))
        issues.append(contentsOf: lintNonEmptyConfig(project: project))
        issues.append(contentsOf: lintConfigNames(settings: project.settings))
        return issues
    }

    func lint(target: Target) -> [LintingIssue] {
        var issues: [LintingIssue] = []
        if let settings = target.settings {
            issues.append(contentsOf: lintConfigFilesExist(settings: settings))
            issues.append(contentsOf: lintConfigNames(settings: settings))
        }
        return issues
    }

    // MARK: - private

    private func lintConfigFilesExist(settings: Settings) -> [LintingIssue] {
        var issues: [LintingIssue] = []

        let lintPath: (AbsolutePath) -> Void = { path in
            if !self.fileHandler.exists(path) {
                issues.append(LintingIssue(reason: "Configuration file not found at path \(path.pathString)", severity: .error))
            }
        }

        settings.configurations.xcconfigs().forEach { configFilePath in
            lintPath(configFilePath)
        }

        return issues
    }

    private func lintNonEmptyConfig(project: Project) -> [LintingIssue] {
        guard !project.settings.configurations.isEmpty else {
            return [LintingIssue(reason: "The project at path \(project.path.pathString) has no configurations", severity: .error)]
        }
        return []
    }

    private func lintConfigNames(settings: Settings) -> [LintingIssue] {
        let configurationNames = settings.configurations.keys.map(\.name)
        let invalidNames = configurationNames.filter { !validConfigurationName(name: $0) }

        return invalidNames.map { _ in
            LintingIssue(reason: "Custom configurations must define a valid name (can't be empty or left unspecified)", severity: .error)
        }
    }

    private func validConfigurationName(name: String) -> Bool {
        return !name.isEmpty
    }
}
