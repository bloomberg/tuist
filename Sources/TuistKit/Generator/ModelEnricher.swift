
import Foundation
import TuistGenerator
import Basic
import class ProjectDescription.TuistConfig

struct TuistConfigManifest {
    var path: AbsolutePath
    var manifest: ProjectDescription.TuistConfig
}

protocol ModelEnriching {
    func enrich(model: Project, using config: TuistConfigManifest) throws -> Project
}

class ModelEnricher: ModelEnriching {
    private let manifestTargetGenerator: ManifestTargetGenerating?
    init(manifestTargetGenerator: ManifestTargetGenerating?) {
        self.manifestTargetGenerator = manifestTargetGenerator
    }
    
    func enrich(model: Project, using config: TuistConfigManifest) throws -> Project {
        var enrichedModel = model
        
        // Manifest Target
        if let manifestTargetGenerator = manifestTargetGenerator,
            config.manifest.generationOptions.contains(.generateManifest) {
            let manifestTarget = try manifestTargetGenerator.generateManifestTarget(for: enrichedModel.name,
                                                                                    at: enrichedModel.path)
            enrichedModel = enrichedModel.adding(target: manifestTarget)
            
        }
        
        // Shared Configurations
        enrichedModel = enrichedModel.replacing(settings: enrich(model: enrichedModel.settings, using: config))
        
        return enrichedModel
    }
    
    private func enrich(model: Settings,
                        using config: TuistConfigManifest) -> Settings {
        if let configurations = config.manifest.sharedConfigurations,
            model.configurations == Settings.default.configurations {
            let configurationsModel = TuistGenerator.Settings.from(manifest: .settings(configurations: configurations),
                                                                   path: config.path)
            return TuistGenerator.Settings(base: model.base,
                                           configurations: configurationsModel.configurations,
                                           defaultSettings: model.defaultSettings)
        }
        return model
    }
}
