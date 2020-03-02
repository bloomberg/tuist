import Foundation
import os.log

public class Signpost {
    private let identifier: StaticString
    private let label: String?
    private let log: OSLog
    private let signpostID: OSSignpostID
    private let printResults: Bool
    private var startTime: Date?
    public init(category: StaticString, identifier: StaticString, label: String?, print: Bool = false) {
        self.identifier = identifier
        self.label = label
        printResults = print
        log = OSLog(subsystem: "io.tuist", category: "\(category)")
        signpostID = OSSignpostID(log: log)
    }

    public func begin() {
        startTime = Date()
        Signpost.createSignPost(.begin, log: log, name: identifier, signpostID: signpostID, label: label)
    }

    public func end() {
        Signpost.createSignPost(.end, log: log, name: identifier, signpostID: signpostID, label: label)
        guard printResults, let start = startTime else {
            return
        }
        let interval = Date().timeIntervalSince(start)
        print(">> \(identifier) = \(interval)")
    }

    public static func measure<T>(category: StaticString,
                                  identifier: StaticString,
                                  label: String? = nil,
                                  _ code: () throws -> T) rethrows -> T {
        let log = OSLog(subsystem: "io.tuist", category: "\(category)")
        let signpostID = OSSignpostID(log: log)

        createSignPost(.begin, log: log, name: identifier, signpostID: signpostID, label: label)
        defer {
            createSignPost(.end, log: log, name: identifier, signpostID: signpostID, label: label)
        }
        return try code()
    }

    public static func measure(category: StaticString,
                               identifier: StaticString,
                               label: String? = nil,
                               _ code: () throws -> Void) rethrows {
        let log = OSLog(subsystem: "io.tuist", category: "\(category)")
        let signpostID = OSSignpostID(log: log)

        createSignPost(.begin, log: log, name: identifier, signpostID: signpostID, label: label)
        defer {
            createSignPost(.end, log: log, name: identifier, signpostID: signpostID, label: label)
        }
        return try code()
    }

    private static func createSignPost(_ event: OSSignpostType,
                                       log: OSLog,
                                       name: StaticString,
                                       signpostID: OSSignpostID,
                                       label: String? = nil) {
        if let label = label {
            os_signpost(event, log: log, name: name, signpostID: signpostID, "%{public}s", label)
        } else {
            os_signpost(event, log: log, name: name, signpostID: signpostID)
        }
    }
}
