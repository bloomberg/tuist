import ProjectDescription

let configurations: [CustomConfiguration] = [
    .debug(name: "Debug", xcconfig: "ConfigurationFiles/Debug.xcconfig"),
    .release(name: "Beta", xcconfig: "ConfigurationFiles/Beta.xcconfig"),
    .release(name: "Release", xcconfig: "ConfigurationFiles/Release.xcconfig"),
]

let tuistConfig = TuistConfig(generationOptions: [],
                              sharedConfigurations: configurations)