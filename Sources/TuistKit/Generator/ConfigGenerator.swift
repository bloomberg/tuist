import Basic
import Foundation
import TuistCore
import xcodeproj

protocol ConfigGenerating: AnyObject {
    func generateProjectConfig(project: Project,
                               pbxproj: PBXProj,
                               fileElements: ProjectFileElements,
                               options: GenerationOptions) throws -> XCConfigurationList

    func generateTargetConfig(_ target: Target,
                              pbxTarget: PBXTarget,
                              pbxproj: PBXProj,
                              projectSettings: Settings,
                              fileElements: ProjectFileElements,
                              options: GenerationOptions,
                              sourceRootPath: AbsolutePath) throws
}

final class ConfigGenerator: ConfigGenerating {
    // MARK: - Attributes

    let fileGenerator: FileGenerating

    // MARK: - Init

    init(fileGenerator: FileGenerating = FileGenerator()) {
        self.fileGenerator = fileGenerator
    }

    // MARK: - ConfigGenerating

    func generateProjectConfig(project: Project,
                               pbxproj: PBXProj,
                               fileElements: ProjectFileElements,
                               options _: GenerationOptions) throws -> XCConfigurationList {
        /// Configuration list
        let configurationList = XCConfigurationList(buildConfigurations: [])
        pbxproj.add(object: configurationList)

        try project.settings.orderedConfigurations().forEach {
            try generateProjectSettingsFor(buildConfiguration: $0.key,
                                           configuration: $0.value,
                                           project: project,
                                           fileElements: fileElements,
                                           pbxproj: pbxproj,
                                           configurationList: configurationList)
        }

        return configurationList
    }

    func generateTargetConfig(_ target: Target,
                              pbxTarget: PBXTarget,
                              pbxproj: PBXProj,
                              projectSettings: Settings,
                              fileElements: ProjectFileElements,
                              options _: GenerationOptions,
                              sourceRootPath: AbsolutePath) throws {
        let configurationList = XCConfigurationList(buildConfigurations: [])
        pbxproj.add(object: configurationList)
        pbxTarget.buildConfigurationList = configurationList

        let projectBuildConfigurations = projectSettings.configurations.keys
        let targetConfigurations = target.settings?.configurations ?? [:]
        let targetBuildConfigurations = targetConfigurations.keys
        let buildConfigurations = Set(projectBuildConfigurations).union(targetBuildConfigurations)
        let configurationsTuples: [(BuildConfiguration, Configuration?)] = buildConfigurations.map {
            if let configuration = target.settings?.configurations[$0] {
                return ($0, configuration)
            }
            return ($0, nil)
        }
        let configurations = Dictionary(uniqueKeysWithValues: configurationsTuples)
        let nonEmptyConfigurations = !configurations.isEmpty ? configurations : Settings.default.configurations
        let orderedConfigurations = Settings.ordered(configurations: nonEmptyConfigurations)
        try orderedConfigurations.forEach {
            try generateTargetSettingsFor(target: target,
                                          buildConfiguration: $0.key,
                                          configuration: $0.value,
                                          fileElements: fileElements,
                                          pbxproj: pbxproj,
                                          configurationList: configurationList,
                                          sourceRootPath: sourceRootPath)
        }
    }

    // MARK: - Fileprivate

    fileprivate func generateProjectSettingsFor(buildConfiguration: BuildConfiguration,
                                                configuration: Configuration?,
                                                project: Project,
                                                fileElements: ProjectFileElements,
                                                pbxproj: PBXProj,
                                                configurationList: XCConfigurationList) throws {
        let variant: BuildSettingsProvider.Variant = settingsProviderVariant(buildConfiguration.variant)
        let defaultConfigSettings = BuildSettingsProvider.projectDefault(variant: variant)
        let defaultSettingsAll = BuildSettingsProvider.projectDefault(variant: .all)

        var settings: [String: Any] = [:]
        extend(buildSettings: &settings, with: defaultSettingsAll)
        extend(buildSettings: &settings, with: project.settings.base)
        extend(buildSettings: &settings, with: defaultConfigSettings)

        let variantBuildConfiguration = XCBuildConfiguration(name: buildConfiguration.name,
                                                             baseConfiguration: nil,
                                                             buildSettings: [:])
        if let variantConfig = configuration {
            extend(buildSettings: &settings, with: variantConfig.settings)
            if let xcconfig = variantConfig.xcconfig {
                let fileReference = fileElements.file(path: xcconfig)
                variantBuildConfiguration.baseConfiguration = fileReference
            }
        }
        variantBuildConfiguration.buildSettings = settings
        pbxproj.add(object: variantBuildConfiguration)
        configurationList.buildConfigurations.append(variantBuildConfiguration)
    }

    fileprivate func generateTargetSettingsFor(target: Target,
                                               buildConfiguration: BuildConfiguration,
                                               configuration: Configuration?,
                                               fileElements: ProjectFileElements,
                                               pbxproj: PBXProj,
                                               configurationList: XCConfigurationList,
                                               sourceRootPath: AbsolutePath) throws {
        let product = settingsProviderProduct(target)
        let platform = settingsProviderPlatform(target)
        let variant: BuildSettingsProvider.Variant = settingsProviderVariant(buildConfiguration.variant)

        var settings: [String: Any] = [:]
        extend(buildSettings: &settings, with: BuildSettingsProvider.targetDefault(variant: .all, platform: platform, product: product, swift: true))
        extend(buildSettings: &settings, with: BuildSettingsProvider.targetDefault(variant: variant, platform: platform, product: product, swift: true))
        extend(buildSettings: &settings, with: target.settings?.base ?? [:])
        extend(buildSettings: &settings, with: configuration?.settings ?? [:])

        let variantBuildConfiguration = XCBuildConfiguration(name: buildConfiguration.name,
                                                             baseConfiguration: nil,
                                                             buildSettings: [:])
        if let variantConfig = configuration {
            if let xcconfig = variantConfig.xcconfig {
                let fileReference = fileElements.file(path: xcconfig)
                variantBuildConfiguration.baseConfiguration = fileReference
            }
        }

        /// Target attributes
        settings["PRODUCT_BUNDLE_IDENTIFIER"] = target.bundleId
        if let infoPlist = target.infoPlist {
            settings["INFOPLIST_FILE"] = "$(SRCROOT)/\(infoPlist.relative(to: sourceRootPath).asString)"
        }
        if let entitlements = target.entitlements {
            settings["CODE_SIGN_ENTITLEMENTS"] = "$(SRCROOT)/\(entitlements.relative(to: sourceRootPath).asString)"
        }
        settings["SDKROOT"] = target.platform.xcodeSdkRoot
        settings["SUPPORTED_PLATFORMS"] = target.platform.xcodeSupportedPlatforms
        // TODO: We should show a warning here
        if settings["SWIFT_VERSION"] == nil {
            settings["SWIFT_VERSION"] = Constants.swiftVersion
        }

        if target.product == .staticFramework {
            settings["MACH_O_TYPE"] = "staticlib"
        }

        variantBuildConfiguration.buildSettings = settings
        pbxproj.add(object: variantBuildConfiguration)
        configurationList.buildConfigurations.append(variantBuildConfiguration)
    }

    fileprivate func settingsProviderVariant(_ variant: BuildConfiguration.Variant) -> BuildSettingsProvider.Variant {
        switch variant {
        case .debug: return .debug
        case .release: return .release
        case .all: return .all
        }
    }

    fileprivate func settingsProviderPlatform(_ target: Target) -> BuildSettingsProvider.Platform? {
        var platform: BuildSettingsProvider.Platform?
        switch target.platform {
        case .iOS: platform = .iOS
        case .macOS: platform = .macOS
        case .tvOS: platform = .tvOS
//        case .watchOS: platform = .watchOS
        }
        return platform
    }

    fileprivate func settingsProviderProduct(_ target: Target) -> BuildSettingsProvider.Product? {
        switch target.product {
        case .app:
            return .application
        case .dynamicLibrary:
            return .dynamicLibrary
        case .staticLibrary:
            return .staticLibrary
        case .framework, .staticFramework:
            return .framework
        default:
            return nil
        }
    }

    fileprivate func extend(buildSettings: inout [String: Any], with other: [String: Any]) {
        other.forEach { key, value in
            if buildSettings[key] == nil || (value as? String)?.contains("$(inherited)") == false {
                buildSettings[key] = value
            } else {
                let previousValue: Any = buildSettings[key]!
                if let previousValueString = previousValue as? String, let newValueString = value as? String {
                    buildSettings[key] = "\(previousValueString) \(newValueString)"
                } else {
                    buildSettings[key] = value
                }
            }
        }
    }
}
