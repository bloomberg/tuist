import ProjectDescription

let settings = Settings(base: [
    "PROJECT_BASE": "PROJECT_BASE",
])

let project = Project(name: "Framework2",
                      settings: settings,
                      targets: [
                          Target(name: "Framework2",
                                 platform: .iOS,
                                 product: .framework,
                                 bundleId: "io.tuist.Framework2",
                                 infoPlist: "Support/Framework2-Info.plist",
                                 sources: "Sources/**",
                                 dependencies: []),
                          Target(name: "Framework2Tests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "io.tuist.Framework2Tests",
                                 infoPlist: "Support/Framework2Tests-Info.plist",
                                 sources: "Tests/**",
                                 dependencies: [
                                     .target(name: "Framework2"),
                          ]),
])
