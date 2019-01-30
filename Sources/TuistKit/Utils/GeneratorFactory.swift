import TuistCore
import TuistGenerator

class GeneratorFactory {

    static func create(printer: Printing, system: Systeming, fileHandler: FileHandling) -> Generating {
        let resourceLocator = TuistGenerator.ResourceLocator(fileHandler: fileHandler)
        let deprecator = Deprecator(printer: printer)
        let manifestLoader = ManifestLoader(fileHandler: fileHandler,
                                            system: system,
                                            deprecator: deprecator)
        let modelLoader = TuistGeneratorModelLoader(fileHandler: fileHandler,
                                                    manifestLoader: manifestLoader)
        let generator = Generator(system: system,
                                  printer: printer,
                                  resourceLocator: resourceLocator,
                                  modelLoader: modelLoader)
        return generator
    }
}
