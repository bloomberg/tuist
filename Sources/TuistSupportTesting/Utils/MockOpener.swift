import Basic
import Foundation
import TuistSupport

public final class MockOpener: Opening {
    var openStub: Error?
    var openArgs: [AbsolutePath] = []
    var openCallCount: UInt = 0

    var openBlockingCalls: [(path: AbsolutePath, newInstance: Bool, blocking: Bool)] = []

    public func open(path: AbsolutePath) throws {
        openCallCount += 1
        openArgs.append(path)
        if let openStub = openStub { throw openStub }
    }

    public func open(path: AbsolutePath,
                     newInstance: Bool,
                     blocking: Bool) throws {
        openBlockingCalls.append((path, newInstance, blocking))
    }
}
