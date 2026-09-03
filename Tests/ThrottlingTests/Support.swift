import Foundation

/// A clock that only moves when a test tells it to.
///
/// It reuses `ContinuousClock.Instant`, so there is no `InstantProtocol`
/// conformance to write. `sleep(until:)` returns immediately, which is safe
/// here because the sequence under test never sleeps: it only reads `now`.
final class ManualClock: Clock, @unchecked Sendable {
    typealias Instant = ContinuousClock.Instant

    private let lock = NSLock()
    private var instant = ContinuousClock.now

    var now: Instant {
        lock.withLock { instant }
    }

    var minimumResolution: Duration { .zero }

    func advance(by duration: Duration) {
        lock.withLock { instant = instant.advanced(by: duration) }
    }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {}
}

/// A base sequence that moves a `ManualClock` forward as it produces elements,
/// so a test can describe arrival times instead of waiting for them.
struct ScriptedSequence: AsyncSequence {
    typealias Element = Int

    let script: [(value: Int, after: Duration)]
    let clock: ManualClock

    struct Iterator: AsyncIteratorProtocol {
        let script: [(value: Int, after: Duration)]
        let clock: ManualClock
        var index = 0

        mutating func next() async -> Int? {
            guard index < script.count else { return nil }

            let step = script[index]
            index += 1
            clock.advance(by: step.after)
            return step.value
        }
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(script: script, clock: clock)
    }
}

struct SampleError: Error {}

/// A sequence that yields one element and then fails.
struct FailingSequence: AsyncSequence {
    typealias Element = Int

    struct Iterator: AsyncIteratorProtocol {
        var didYield = false

        mutating func next() async throws -> Int? {
            guard didYield else {
                didYield = true
                return 1
            }
            throw SampleError()
        }
    }

    func makeAsyncIterator() -> Iterator { Iterator() }
}
