import XCTest
@testable import MiniTimerCore

@MainActor
final class TimerStoreTests: XCTestCase {
    func testTickAdvancesWhenRunningAndFocusedAppIsAllowed() {
        let store = TimerStore()
        let app = AppFocusInfo(localizedName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode")

        store.play()
        store.tick(focusedApp: app, isExcluded: false)

        XCTAssertEqual(store.elapsedSeconds, 1)
        XCTAssertFalse(store.isAutoPaused)
        XCTAssertEqual(store.state, .running)
        XCTAssertEqual(store.lastFocusedApp, app)
    }

    func testTickDoesNotAdvanceWhenManuallyPaused() {
        let store = TimerStore()

        store.tick(focusedApp: nil, isExcluded: false)

        XCTAssertEqual(store.elapsedSeconds, 0)
        XCTAssertFalse(store.isAutoPaused)
        XCTAssertEqual(store.state, .manuallyPaused)
    }

    func testTickDoesNotAdvanceWhenFocusedAppIsExcluded() {
        let store = TimerStore()
        let app = AppFocusInfo(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")

        store.play()
        store.tick(focusedApp: app, isExcluded: true)

        XCTAssertEqual(store.elapsedSeconds, 0)
        XCTAssertTrue(store.isAutoPaused)
        XCTAssertEqual(store.state, .autoPaused)
    }

    func testRefreshFocusStateUpdatesAutoPauseWithoutAdvancingElapsedTime() {
        let store = TimerStore(elapsedSeconds: 12, isManuallyRunning: true)
        let app = AppFocusInfo(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")

        store.refreshFocusState(focusedApp: app, isExcluded: true)

        XCTAssertEqual(store.elapsedSeconds, 12)
        XCTAssertTrue(store.isAutoPaused)
        XCTAssertEqual(store.state, .autoPaused)
        XCTAssertEqual(store.lastFocusedApp, app)
    }

    func testPauseClearsAutoPauseState() {
        let store = TimerStore()

        store.play()
        store.tick(focusedApp: nil, isExcluded: true)
        store.pause()

        XCTAssertFalse(store.isManuallyRunning)
        XCTAssertFalse(store.isAutoPaused)
        XCTAssertEqual(store.state, .manuallyPaused)
    }

    func testResetReturnsElapsedTimeToZero() {
        let store = TimerStore(elapsedSeconds: 42, isManuallyRunning: true)

        store.reset()

        XCTAssertEqual(store.elapsedSeconds, 0)
        XCTAssertTrue(store.isManuallyRunning)
    }

    func testFormattedElapsedUsesHHMMSS() {
        let store = TimerStore(elapsedSeconds: 3_661)

        XCTAssertEqual(store.formattedElapsed, "01:01:01")
    }
}
