import Foundation

/// A session measures elapsed time, including short input-free pauses.
/// An input-free interval >= idleReset resets it and waits for new input.
struct SessionTimer {
    enum Phase: Equatable { case working, reminder, resting, paused }
    var phase: Phase = .working
    var elapsed: TimeInterval = 0
    var workInterval: TimeInterval = 30 * 60
    var restInterval: TimeInterval = 30
    var idleReset: TimeInterval? = 2 * 60
    private(set) var restRemaining: TimeInterval = 30
    private(set) var waitingForInput = false
    private(set) var didCompleteRest = false
    private var previousUptime: TimeInterval?
    private var restDeadline: TimeInterval?

    mutating func reset(waitForInput: Bool = true) {
        didCompleteRest = false
        phase = .working
        elapsed = 0
        waitingForInput = waitForInput
        previousUptime = nil
        restDeadline = nil
        restRemaining = restInterval
    }

    mutating func setPaused(_ paused: Bool) {
        reset()
        if paused { phase = .paused }
    }

    mutating func startRest(now: TimeInterval) {
        phase = .resting
        restRemaining = restInterval
        restDeadline = now + restInterval
        previousUptime = now
    }

    mutating func snooze(seconds: TimeInterval = 300) {
        reset(waitForInput: false)
        elapsed = max(0, workInterval - seconds)
    }

    /// Returns true only when a reminder first becomes due.
    mutating func tick(now: TimeInterval, idle: TimeInterval, unavailable: Bool) -> Bool {
        didCompleteRest = false
        let previous = previousUptime
        let delta = previous.map { max(0, now - $0) } ?? 0
        previousUptime = now
        if phase == .paused { return false }
        // Long gaps indicate suspension or an unserviced process, not verified work.
        if unavailable || (previous != nil && delta > 15) {
            reset()
            previousUptime = now
            return false
        }
        if phase == .resting {
            restRemaining = max(0, (restDeadline ?? now) - now)
            if restRemaining <= 0 { reset(); didCompleteRest = true }
            return false
        }
        if let threshold = idleReset, idle >= threshold {
            reset()
            previousUptime = now
            return false
        }
        if waitingForInput {
            // Accept input since the last timer tick; do not count absence as work.
            guard idle <= max(delta, 1.25) else { return false }
            waitingForInput = false
            return false
        }
        guard phase == .working else { return false }
        elapsed += delta
        if elapsed >= workInterval {
            phase = .reminder
            return true
        }
        return false
    }
}
