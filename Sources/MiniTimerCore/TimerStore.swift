import Combine
import Foundation

public enum TimerRunState: String, Equatable {
    case running
    case manuallyPaused = "manual-paused"
    case autoPaused = "auto-paused"
}

@MainActor
public final class TimerStore: ObservableObject {
    @Published public private(set) var elapsedSeconds: Int
    @Published public private(set) var isManuallyRunning: Bool
    @Published public private(set) var isAutoPaused: Bool
    @Published public private(set) var lastFocusedApp: AppFocusInfo?

    public init(elapsedSeconds: Int = 0, isManuallyRunning: Bool = false) {
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.isManuallyRunning = isManuallyRunning
        self.isAutoPaused = false
        self.lastFocusedApp = nil
    }

    public var state: TimerRunState {
        if !isManuallyRunning {
            return .manuallyPaused
        }

        return isAutoPaused ? .autoPaused : .running
    }

    public var formattedElapsed: String {
        DurationFormatting.string(from: elapsedSeconds)
    }

    public func play() {
        isManuallyRunning = true
    }

    public func pause() {
        isManuallyRunning = false
        isAutoPaused = false
    }

    public func reset() {
        elapsedSeconds = 0
    }

    public func refreshFocusState(focusedApp: AppFocusInfo?, isExcluded: Bool) {
        lastFocusedApp = focusedApp

        guard isManuallyRunning else {
            isAutoPaused = false
            return
        }

        isAutoPaused = isExcluded
    }

    public func tick(focusedApp: AppFocusInfo?, isExcluded: Bool) {
        refreshFocusState(focusedApp: focusedApp, isExcluded: isExcluded)

        guard isManuallyRunning && !isExcluded else {
            return
        }

        elapsedSeconds += 1
    }
}
