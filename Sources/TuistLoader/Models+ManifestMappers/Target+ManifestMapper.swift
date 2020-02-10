import Basic
import Foundation
import ProjectDescription
import TuistCore

extension TuistCore.Target {
    // swiftlint:disable:next function_body_length
    static func from(manifest: ProjectDescription.Target,
                     path: AbsolutePath,
                     generatorPaths: GeneratorPaths) throws -> TuistCore.Target {
        let name = manifest.name
        let platform = try TuistCore.Platform.from(manifest: manifest.platform)
        let product = TuistCore.Product.from(manifest: manifest.product)

        let bundleId = manifest.bundleId
        let productName = manifest.productName
        let deploymentTarget = manifest.deploymentTarget.map { TuistCore.DeploymentTarget.from(manifest: $0) }

        let dependencies = try manifest.dependencies.map { try TuistCore.Dependency.from(manifest: $0, generatorPaths: generatorPaths) }

        let infoPlist = try TuistCore.InfoPlist.from(manifest: manifest.infoPlist, path: path, generatorPaths: generatorPaths)
        let entitlements = try manifest.entitlements.map { try generatorPaths.resolve(path: $0) }

        let settings = try manifest.settings.map { try TuistCore.Settings.from(manifest: $0, path: path, generatorPaths: generatorPaths) }
        let sources = try TuistCore.Target.sources(projectPath: path,
                                                   sources: manifest.sources?.globs.map { (glob: ProjectDescription.SourceFileGlob) in
                                                       let globPath = try generatorPaths.resolve(path: glob.glob).pathString
                                                       let excluding: [String] = try glob.excluding.compactMap { try generatorPaths.resolve(path: $0).pathString }
                                                       return (glob: globPath, excluding: excluding, compilerFlags: glob.compilerFlags)
        } ?? [])

        let resourceFilter = { (path: AbsolutePath) -> Bool in
            TuistCore.Target.isResource(path: path)
        }
        let resources = try (manifest.resources ?? []).flatMap {
            try TuistCore.FileElement.from(manifest: $0,
                                           path: path,
                                           generatorPaths: generatorPaths,
                                           includeFiles: resourceFilter)
        }

        let headers = try manifest.headers.map { try TuistCore.Headers.from(manifest: $0, path: path, generatorPaths: generatorPaths) }

        let coreDataModels = try manifest.coreDataModels.map {
            try TuistCore.CoreDataModel.from(manifest: $0, path: path, generatorPaths: generatorPaths)
        }

        let actions = try manifest.actions.map { try TuistCore.TargetAction.from(manifest: $0, path: path, generatorPaths: generatorPaths) }
        let environment = manifest.environment

        return TuistCore.Target(name: name,
                                platform: platform,
                                product: product,
                                productName: productName,
                                bundleId: bundleId,
                                deploymentTarget: deploymentTarget,
                                infoPlist: infoPlist,
                                entitlements: entitlements,
                                settings: settings,
                                sources: sources,
                                resources: resources,
                                headers: headers,
                                coreDataModels: coreDataModels,
                                actions: actions,
                                environment: environment,
                                filesGroup: .group(name: "Project"),
                                dependencies: dependencies)
    }
}
