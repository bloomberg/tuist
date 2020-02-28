import Foundation
import Basic

/// Ensures that writing and reading from property annotated with this property wrapper is thread safe
/// Taken from https://www.onswiftwings.com/posts/atomic-property-wrapper/
@propertyWrapper
public class Atomic<Value> {
    private var value: Value
    private let lock = Lock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
        get {
            return lock.withLock {
                value
            }
        }
        set {
            lock.withLock {
                value = newValue
            }
        }
    }

    public func modify<T>(_ access: (inout Value) -> T) -> T {
        lock.withLock {
            access(&value)
        }
    }
}
