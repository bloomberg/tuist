import Foundation

struct GeneratorConfig {
    var projects: Int
    var targets: Int
    var sources: Int
    var headers: Int
    var resources: Int
    var additionalGlobs: Int
    var dependencies: Bool
}

extension GeneratorConfig {
    static var `default`: GeneratorConfig {
        GeneratorConfig(projects: 5,
                        targets: 10,
                        sources: 50,
                        headers: 20,
                        resources: 20,
                        additionalGlobs: 0,
                        dependencies: false)
    }
}
