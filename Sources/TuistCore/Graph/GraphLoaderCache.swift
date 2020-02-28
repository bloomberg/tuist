import Basic
import Foundation
import TuistSupport

/// Graph loader cache.
public class GraphLoaderCache: GraphLoaderCaching {
    /// Initializer
    public init() {}

    // MARK: - GraphLoaderCaching

    @Atomic
    var tuistConfigs: [AbsolutePath: TuistConfig] = [:]

    @Atomic
    public var projects: [AbsolutePath: Project] = [:]

    @Atomic
    public var packages: [AbsolutePath: [PackageNode]] = [:]

    @Atomic
    public var precompiledNodes: [AbsolutePath: PrecompiledNode] = [:]

    @Atomic
    public var targetNodes: [AbsolutePath: [String: TargetNode]] = [:]

    /// Cached CocoaPods nodes
    @Atomic
    public var cocoapodsNodes: [AbsolutePath: CocoaPodsNode] = [:]

    /// Cached SwiftPM package nodes
    @Atomic
    public var packageNodes: [AbsolutePath: PackageProductNode] = [:]

    /// Returns, if it exists, the CocoaPods node at the given path.
    ///
    /// - Parameter path: Path to the directory where the Podfile is defined.
    /// - Returns: The CocoaPods node if it exists in the cache.
    public func cocoapods(_ path: AbsolutePath) -> CocoaPodsNode? {
        cocoapodsNodes[path]
    }

    /// Adds a parsed CocoaPods graph node to the cache.
    ///
    /// - Parameter cocoapods: Node to be added to the cache.
    public func add(cocoapods: CocoaPodsNode) {
        _cocoapodsNodes.modify {
            $0[cocoapods.path] = cocoapods
        }
    }

    /// Returns, if it exists, the Package node at the given path.
    ///
    /// - Parameter path: Path to the directory where the Podfile is defined.
    /// - Returns: The Package node if it exists in the cache.
    public func package(_ path: AbsolutePath) -> PackageProductNode? {
        packageNodes[path]
    }

    /// Adds a parsed Package graph node to the cache.
    ///
    /// - Parameter package: Node to be added to the cache.
    public func add(package: PackageProductNode) {
        _packageNodes.modify {
            $0[package.path] = package
        }
    }

    public func tuistConfig(_ path: AbsolutePath) -> TuistConfig? {
        tuistConfigs[path]
    }

    public func add(tuistConfig: TuistConfig, path: AbsolutePath) {
        _tuistConfigs.modify {
            $0[path] = tuistConfig
        }
    }

    public func project(_ path: AbsolutePath) -> Project? {
        projects[path]
    }

    public func add(project: Project) {
        _projects.modify {
            $0[project.path] = project
        }

        _packages.modify {
            $0[project.path] = project.packages.map { PackageNode(package: $0, path: project.path) }
        }
    }

    public func add(precompiledNode: PrecompiledNode) {
        _precompiledNodes.modify {
            $0[precompiledNode.path] = precompiledNode
        }
    }

    public func precompiledNode(_ path: AbsolutePath) -> PrecompiledNode? {
        precompiledNodes[path]
    }

    public func add(targetNode: TargetNode) {
        _targetNodes.modify {
            var projectTargets: [String: TargetNode] = $0[targetNode.path, default: [:]]
            projectTargets[targetNode.target.name] = targetNode
            $0[targetNode.path] = projectTargets
        }
    }

    public func targetNode(_ path: AbsolutePath, name: String) -> TargetNode? {
        targetNodes[path]?[name]
    }
}
