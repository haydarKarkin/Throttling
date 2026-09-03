public extension AsyncSequence {
    /// Passes the first element of every `interval` long window through and
    /// drops every element that arrives before the window is over.
    ///
    /// - Parameters:
    ///   - interval: The shortest time allowed between two elements.
    ///   - clock: The clock measuring the interval.
    func throttleFirst<C: Clock>(
        for interval: C.Duration,
        clock: C,
    ) -> AsyncThrottleFirstSequence<Self, C> {
        AsyncThrottleFirstSequence(base: self, interval: interval, clock: clock)
    }

    /// Passes the first element of every `interval` long window through,
    /// measured on the continuous clock.
    ///
    /// - Parameter interval: The shortest time allowed between two elements.
    func throttleFirst(
        for interval: Duration,
    ) -> AsyncThrottleFirstSequence<Self, ContinuousClock> {
        throttleFirst(for: interval, clock: ContinuousClock())
    }
}
