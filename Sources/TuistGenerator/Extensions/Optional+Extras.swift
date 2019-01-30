extension Optional {

    func valueOrThrow(_ error: Error) throws -> Wrapped {
        switch (self) {
        case let .some(value):
            return value
        case .none:
            throw error
        }
    }
}
