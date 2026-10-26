import Foundation

@main struct TimerTests {
    static func main() {
        var assertions = 0
        func check(_ condition: @autoclosure () -> Bool, _ label: String) {
            precondition(condition(), label)
            assertions += 1
        }
        func advance(_ timer: inout SessionTimer, from: Int, through: Int, idle: Double = 0) {
            for t in from...through { _ = timer.tick(now: Double(t), idle: idle, unavailable: false) }
        }
        var session = SessionTimer()
        _ = session.tick(now: 0, idle: 0, unavailable: false)
        advance(&session, from: 1, through: 1799)
        check(session.phase == .working, "No early reminder")
        check(session.tick(now: 1800, idle: 0, unavailable: false), "Reminder at 30 min")
        check(!session.tick(now: 1801, idle: 0, unavailable: false), "Only one reminder")
        session.startRest(now: 1801)
        advance(&session, from: 1802, through: 1830)
        check(session.phase == .resting, "Rest lasts full 30 seconds")
        _ = session.tick(now: 1831, idle: 10, unavailable: false)
        check(session.phase == .working && session.elapsed == 0 && session.waitingForInput, "Rest resets session")
        check(session.didCompleteRest, "Natural countdown completion is signalled")
        _ = session.tick(now: 1832, idle: 11, unavailable: false)
        check(session.waitingForInput && session.elapsed == 0, "Wait for input after rest")
        _ = session.tick(now: 1833, idle: 0, unavailable: false)
        check(!session.waitingForInput, "New input starts session")

        session.reset(waitForInput: false)
        session.idleReset = 300
        _ = session.tick(now: 0, idle: 0, unavailable: false)
        advance(&session, from: 1, through: 299, idle: 299)
        check(session.elapsed == 299, "Short pauses count")
        _ = session.tick(now: 300, idle: 300, unavailable: false)
        check(session.elapsed == 0 && session.waitingForInput, "Idle threshold resets")
        advance(&session, from: 301, through: 500, idle: 500)
        check(session.elapsed == 0, "Long absence does not accrue time")
        _ = session.tick(now: 501, idle: 0, unavailable: false)
        _ = session.tick(now: 502, idle: 0, unavailable: false)
        check(session.elapsed == 1, "Restart after return")
        _ = session.tick(now: 503, idle: 0, unavailable: true)
        check(session.elapsed == 0 && session.waitingForInput, "Lock/sleep resets")

        session.idleReset = nil
        session.reset(waitForInput: false)
        _ = session.tick(now: 0, idle: 600, unavailable: false)
        advance(&session, from: 1, through: 1800, idle: 2400)
        check(session.phase == .reminder, "Reading mode ignores idle")
        session.snooze()
        _ = session.tick(now: 2000, idle: 0, unavailable: false)
        advance(&session, from: 2001, through: 2299)
        check(session.phase == .working, "Snooze is not early")
        check(session.tick(now: 2300, idle: 0, unavailable: false), "Snooze exactly five min")
        session.setPaused(true)
        advance(&session, from: 2301, through: 2400)
        check(session.phase == .paused && session.elapsed == 0, "Paused time excluded")
        session.setPaused(false)
        _ = session.tick(now: 2500, idle: 0, unavailable: false)
        _ = session.tick(now: 2600, idle: 0, unavailable: false)
        check(session.elapsed == 0 && session.waitingForInput, "Suspension gap resets")
        session.startRest(now: 2700)
        _ = session.tick(now: 2701, idle: 0, unavailable: true)
        check(session.phase == .working && session.elapsed == 0, "Lock cancels ongoing countdown")
        check(!session.didCompleteRest, "Lock is not reported as completed rest")
        session.startRest(now: 2800)
        _ = session.tick(now: 2820, idle: 0, unavailable: false)
        check(!session.didCompleteRest && session.phase == .working, "Suspension does not falsely complete rest")
        var defaultRule = SessionTimer()
        check(defaultRule.idleReset == 120, "User-selected default is two minutes")
        _ = defaultRule.tick(now: 0, idle: 0, unavailable: false)
        advance(&defaultRule, from: 1, through: 119, idle: 119)
        check(defaultRule.elapsed == 119, "Pauses below two minutes count")
        _ = defaultRule.tick(now: 120, idle: 120, unavailable: false)
        check(defaultRule.elapsed == 0 && defaultRule.waitingForInput, "Two-minute threshold resets")
        print("PASS: \(assertions) session timing assertions")
    }
}
