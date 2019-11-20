import ProjectDescription

let userScheme = Scheme(name: "SomeExampleCustomScheme",
                        shared: false,
                        buildAction: BuildAction(targets: [.project(path: "Frameworks/Framework1", target: "Framework1")], preActions: []),
                        testAction: TestAction(targets: [.project(path: "Frameworks/Framework1", target: "Framework1Tests")]),
                        runAction: RunAction(executable: "App"))

let workspace = Workspace(name: "Workspace",
                          projects: [
                              "App",
                              "Frameworks/**",
                            ],
                          schemes: [userScheme])
