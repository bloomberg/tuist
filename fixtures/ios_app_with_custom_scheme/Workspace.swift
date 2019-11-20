import ProjectDescription

let userScheme = WorkspaceDescription.Scheme(name: "SomeExampleCustomScheme",
                                            shared: false,
                                            buildAction: WorkspaceDescription.BuildAction(targets: [.project(path: "Frameworks/Framework1", target: "Framework1")]),
                                            testAction: WorkspaceDescription.TestAction(targets: [.project(path: "Frameworks/Framework1", target: "Framework1Tests")]),
                                            runAction: WorkspaceDescription.RunAction(executable: .project(path: "App", target: "App"))
                                            )

let workspace = Workspace(name: "Workspace",
                          projects: [
                              "App",
                              "Frameworks/**",
                            ],
                          schemes: [userScheme])
