import Basic
import Foundation
@testable import TuistKit

extension Configuration {
    static func test(settings: [String: String] = [:],
                     xcconfig: AbsolutePath? = AbsolutePath("/Config.xcconfig")) -> Configuration {
        return Configuration(settings: settings,
                             xcconfig: xcconfig)
    }
}

extension Settings {
    static func test(base: [String: String] = [:],
                     debug: Configuration = Configuration(settings: [:], xcconfig: AbsolutePath("/Debug.xcconfig")),
                     release: Configuration = Configuration(settings: [:], xcconfig: AbsolutePath("/Release.xcconfig"))
        ) -> Settings {
        return Settings(base: base,
                        configurations: [.debug: debug, .release: release])
    }

    static func test(base: [String: String] = [:],
                     configurations: [BuildConfiguration: Configuration?]? = nil) -> Settings {
        return Settings(base: base, configurations: configurations ?? [
            .debug: Configuration(settings: [:], xcconfig: AbsolutePath("/Debug.xcconfig")),
            .release: Configuration(xcconfig: AbsolutePath("/Debug.xcconfig"))
        ])
    }
}
