/// An async sequence that passes the first element of every time window
/// through and drops the rest.
public struct AsyncThrottleFirstSequence<Base: AsyncSequence, C: Clock>: AsyncSequence {
    public typealias Element = Base.Element

    let base: Base
    let interval: C.Duration
    let clock: C

    public struct Iterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        let interval: C.Duration
        let clock: C
        var windowStart: C.Instant?

        public mutating func next() async throws -> Element? {
            while let element = try await base.next() {
                let now = clock.now

                if let windowStart, windowStart.duration(to: now) < interval {
                    continue
                }

                windowStart = now
                return element
            }

            return nil
        }
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator(), interval: interval, clock: clock)
    }
}

extension AsyncThrottleFirstSequence: Sendable where Base: Sendable, C: Sendable {}
