import Foundation
import XCTest
@testable import ProjectDescription

final class TargetTests: XCTestCase {
    func test_toJSON() {
        let subject = Target(name: "name",
                             platform: .iOS,
                             product: .app,
                             bundleId: "bundle_id",
                             infoPlist: "info.plist",
                             sources: "sources/*",
                             resources: "resources/*",
                             headers: Headers(public: "public/*",
                                              private: "private/*",
                                              project: "project/*"),
                             entitlements: "entitlement",
                             actions: [
                                 TargetAction.post(path: "path", arguments: ["arg"], name: "name"),
                             ],
                             dependencies: [
                                 .framework(path: "path"),
                                 .library(path: "path", publicHeaders: "public", swiftModuleMap: "module"),
                                 .project(target: "target", path: "path"),
                                 .target(name: "name"),
                             ],
                             settings: Settings(
                                base: ["base": "base"],
                                configurations: [
                                    .debug(name: "Debug", settings: ["debug": "debug"], xcconfig: "/path/debug.xcconfig"),
                                    .release(name: "Release", settings: ["release": "release"], xcconfig: "/path/release.xcconfig")
                             ]).asLink(),
                             coreDataModels: [CoreDataModel("pat", currentVersion: "version")],
                             environment: ["a": "b"])

        let expected = "{\"actions\":[{\"arguments\":[\"arg\"],\"name\":\"name\",\"order\":\"post\",\"path\":\"path\"}],\"bundle_id\":\"bundle_id\",\"core_data_models\":[{\"current_version\":\"version\",\"path\":\"pat\"}],\"dependencies\":[{\"path\":\"path\",\"type\":\"framework\"},{\"path\":\"path\",\"public_headers\":\"public\",\"swift_module_map\":\"module\",\"type\":\"library\"},{\"path\":\"path\",\"target\":\"target\",\"type\":\"project\"},{\"name\":\"name\",\"type\":\"target\"}],\"entitlements\":\"entitlement\",\"environment\":{\"a\":\"b\"},\"headers\":{\"private\":\"private\\/*\",\"project\":\"project\\/*\",\"public\":\"public\\/*\"},\"info_plist\":\"info.plist\",\"name\":\"name\",\"platform\":\"ios\",\"product\":\"app\",\"resources\":{\"globs\":[\"resources\\/*\"]},\"settings\":{\"value\":{\"base\":{\"base\":\"base\"},\"configurations\":[{\"buildConfiguration\":\"debug\",\"name\":\"Debug\",\"settings\":{\"debug\":\"debug\"},\"xcconfig\":\"\\/path\\/debug.xcconfig\"},{\"buildConfiguration\":\"release\",\"name\":\"Release\",\"settings\":{\"release\":\"release\"},\"xcconfig\":\"\\/path\\/release.xcconfig\"}]}},\"sources\":{\"globs\":[\"sources\\/*\"]}}"
        assertCodableEqualToJson(subject, expected)
    }

    func test_toJSON_withFileList() {
        let subject = Target(name: "name",
                             platform: .iOS,
                             product: .app,
                             bundleId: "bundle_id",
                             infoPlist: "info.plist",
                             sources: FileList(globs: ["sources/*"]),
                             resources: FileList(globs: ["resources/*"]),
                             headers: Headers(public: "public/*",
                                              private: "private/*",
                                              project: "project/*"),
                             entitlements: "entitlement",
                             actions: [
                                 TargetAction.post(path: "path", arguments: ["arg"], name: "name"),
                             ],
                             dependencies: [
                                 .framework(path: "path"),
                                 .library(path: "path", publicHeaders: "public", swiftModuleMap: "module"),
                                 .project(target: "target", path: "path"),
                                 .target(name: "name"),
                             ],
                             settings: Settings(
                                base: ["base": "base"],
                                configurations: [
                                    .debug(name: "Debug", settings: ["debug": "debug"]),
                                    .release(name: "Release", settings: ["release": "release"])
                             ]).asLink(),
                             coreDataModels: [CoreDataModel("pat", currentVersion: "version")],
                             environment: ["a": "b"])

        let expected = "{\"actions\":[{\"arguments\":[\"arg\"],\"name\":\"name\",\"order\":\"post\",\"path\":\"path\"}],\"bundle_id\":\"bundle_id\",\"core_data_models\":[{\"current_version\":\"version\",\"path\":\"pat\"}],\"dependencies\":[{\"path\":\"path\",\"type\":\"framework\"},{\"path\":\"path\",\"public_headers\":\"public\",\"swift_module_map\":\"module\",\"type\":\"library\"},{\"path\":\"path\",\"target\":\"target\",\"type\":\"project\"},{\"name\":\"name\",\"type\":\"target\"}],\"entitlements\":\"entitlement\",\"environment\":{\"a\":\"b\"},\"headers\":{\"private\":\"private\\/*\",\"project\":\"project\\/*\",\"public\":\"public\\/*\"},\"info_plist\":\"info.plist\",\"name\":\"name\",\"platform\":\"ios\",\"product\":\"app\",\"resources\":{\"globs\":[\"resources\\/*\"]},\"settings\":{\"value\":{\"base\":{\"base\":\"base\"},\"configurations\":[{\"buildConfiguration\":\"debug\",\"name\":\"Debug\",\"settings\":{\"debug\":\"debug\"}},{\"buildConfiguration\":\"release\",\"name\":\"Release\",\"settings\":{\"release\":\"release\"}}]}},\"sources\":{\"globs\":[\"sources\\/*\"]}}"
        assertCodableEqualToJson(subject, expected)
    }
}
