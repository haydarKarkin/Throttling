import Foundation
import Testing

@testable import Throttling

@Suite("throttleFirst")
struct ThrottleFirstTests {
    private func collect<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
        var result: [S.Element] = []
        for try await element in sequence {
            result.append(element)
        }
        return result
    }

    @Test("passes the first element through immediately")
    func passesFirstElement() async throws {
        let clock = ManualClock()
        let base = ScriptedSequence(script: [(1, .zero)], clock: clock)

        let result = try await collect(base.throttleFirst(for: .milliseconds(100), clock: clock))

        #expect(result == [1])
    }

    @Test("drops elements that arrive inside the window")
    func dropsElementsInsideWindow() async throws {
        let clock = ManualClock()
        let base = ScriptedSequence(
            script: [
                (1, .zero),             // t = 0,   first element, passes
                (2, .milliseconds(50)), // t = 50,  window still open, dropped
                (3, .milliseconds(60)), // t = 110, window over, passes
                (4, .milliseconds(500)), // t = 610, window over, passes
                (5, .milliseconds(10)), // t = 620, window still open, dropped
            ],
            clock: clock,
        )

        let result = try await collect(base.throttleFirst(for: .milliseconds(100), clock: clock))

        #expect(result == [1, 3, 4])
    }

    @Test("an element exactly on the boundary passes")
    func boundaryElementPasses() async throws {
        let clock = ManualClock()
        let base = ScriptedSequence(
            script: [
                (1, .zero),
                (2, .milliseconds(100)),
            ],
            clock: clock,
        )

        let result = try await collect(base.throttleFirst(for: .milliseconds(100), clock: clock))

        #expect(result == [1, 2])
    }

    @Test("an empty base sequence stays empty")
    func emptyBase() async throws {
        let clock = ManualClock()
        let base = ScriptedSequence(script: [], clock: clock)

        let result = try await collect(base.throttleFirst(for: .milliseconds(100), clock: clock))

        #expect(result.isEmpty)
    }

    @Test("errors from the base sequence are not swallowed")
    func propagatesErrors() async throws {
        var iterator = FailingSequence()
            .throttleFirst(for: .milliseconds(100), clock: ManualClock())
            .makeAsyncIterator()

        #expect(try await iterator.next() == 1)
        await #expect(throws: SampleError.self) {
            try await iterator.next()
        }
    }

    @Test("works on the continuous clock too")
    func continuousClock() async throws {
        let stream = AsyncStream<Int> { continuation in
            for value in 1...20 {
                continuation.yield(value)
            }
            continuation.finish()
        }

        // Every element is already buffered when iteration starts, so a one
        // second window can only let the first one through. Nothing here
        // depends on how fast the machine is.
        let result = try await collect(stream.throttleFirst(for: .seconds(1)))

        #expect(result == [1])
    }
}
