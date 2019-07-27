import ProjectDescription

let settings = Settings(base: [
    "PROJECT_BASE": "PROJECT_BASE",
])

let betaScheme = Scheme(name: "App-Beta",
                         shared: true,
                         buildAction: BuildAction(targets: ["App"]),
                         runAction: RunAction(configurationName: "Beta", executable: "App"))

let project = Project(name: "MainApp",
                      settings: settings,
                      targets: [
                          Target(name: "App",
                                 platform: .iOS,
                                 product: .app,
                                 bundleId: "io.tuist.App",
                                 infoPlist: "Support/App-Info.plist",
                                 sources: "Sources/**",
                                 dependencies: [
                                     .project(target: "Framework1", path: "../Framework1"),
                                     .project(target: "Framework2", path: "../Framework2"),
                          ]),
                          Target(name: "AppTests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "io.tuist.AppTests",
                                 infoPlist: "Support/AppTests-Info.plist",
                                 sources: "Tests/**",
                                 dependencies: [
                                     .target(name: "App"),
                          ]),
                      ], schemes: [betaScheme])
