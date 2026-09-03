# Throttling

An `AsyncSequence` operator that passes the first element of every time window
through and drops everything that arrives before the window is over.

This is the leading edge variant of throttling: it never waits and never
buffers. It is also a worked example for writing your own `AsyncSequence`
operator, which is what the [article][article] behind it is about.

## Requirements

Swift 6.0, iOS 16, macOS 13.

## Installation

```swift
.package(url: "https://github.com/haydarKarkin/Throttling.git", from: "1.0.0")
```

## Usage

```swift
import Throttling

for try await update in updates.throttleFirst(for: .milliseconds(500)) {
    render(update)
}
```

Pass your own clock when you need one, which is what the tests do:

```swift
updates.throttleFirst(for: .milliseconds(500), clock: myClock)
```

## Semantics

With a window of 100ms:

| Element arrives at | Result |
|---|---|
| 0ms | passes, window opens |
| 50ms | dropped, window still open |
| 110ms | passes, new window opens |
| 610ms | passes, new window opens |
| 620ms | dropped |

The first element always passes, because there is no window open yet.

If the stream starts with a value you do not care about, filter it out before
throttling. Otherwise that value opens the window and the first value you
actually want gets dropped:

```swift
updates
    .filter { !$0.isEmpty }
    .throttleFirst(for: .milliseconds(500))
```

## Layout

```
Sources/Throttling/
├── AsyncThrottleFirstSequence.swift   # the sequence and its iterator
└── AsyncSequence+ThrottleFirst.swift  # the entry point
Tests/ThrottlingTests/
├── Support.swift                      # manual clock, scripted base sequence
└── ThrottleFirstTests.swift
```

## Tests

```bash
swift test
```

The operator is generic over `Clock`, so the tests inject a clock they move by
hand. No test sleeps, and the whole suite runs in a few milliseconds.

## When to use something else

If you need the newest element of each window instead of the oldest, or you
want the operator to wait out the window before emitting, use
[swift-async-algorithms][aa] and its `throttle(for:clock:latest:)`. This
package is not a replacement for it.

## License

MIT

[article]: https://haydarkarkin.com/documentation/releasenotes/asyncsequenceoperator
[aa]: https://github.com/apple/swift-async-algorithms
