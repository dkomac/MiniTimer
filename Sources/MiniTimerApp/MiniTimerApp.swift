import AppKit
import SwiftUI
import MiniTimerCore

@MainActor
final class MiniTimerController: ObservableObject {
    @Published private(set) var elapsedLabel: String
    @Published private(set) var isRunning: Bool
    @Published private(set) var stateLabel: String
    @Published private(set) var focusedAppLabel: String
    @Published private(set) var lastError: String?

    private let timerStore: TimerStore
    private let focusMonitor: FocusMonitor
    private var pauseConfigStore: PauseConfigStore?
    private var sessionLogStore: SessionLogStore?
    private var tickTimer: Timer?

    init() {
        self.timerStore = TimerStore()
        self.focusMonitor = FocusMonitor()
        self.elapsedLabel = timerStore.formattedElapsed
        self.isRunning = timerStore.isManuallyRunning
        self.stateLabel = timerStore.state.rawValue
        self.focusedAppLabel = "unknown"
        self.lastError = nil

        configureStorage()
        timerStore.play()
        syncPublishedState()
        startTicking()
    }

    deinit {
        tickTimer?.invalidate()
    }

    func togglePlayPause() {
        if timerStore.isManuallyRunning {
            timerStore.pause()
        } else {
            timerStore.play()
        }

        syncPublishedState()
    }

    func reset() {
        timerStore.reset()
        syncPublishedState()
    }

    func save() {
        guard let sessionLogStore else {
            lastError = "Session log is unavailable."
            return
        }

        let focusedApp = refreshFocusStateForCurrentApp()

        let snapshot = SessionSnapshot(
            date: Date(),
            elapsedSeconds: timerStore.elapsedSeconds,
            state: timerStore.state,
            focusedApp: focusedApp
        )

        do {
            try sessionLogStore.append(snapshot)
            lastError = nil
        } catch {
            lastError = "Save failed: \(error.localizedDescription)"
        }
    }

    func openConfig() {
        guard let url = pauseConfigStore?.fileURL else {
            lastError = "Config file is unavailable."
            return
        }

        if NSWorkspace.shared.open(url) {
            lastError = nil
        } else {
            lastError = "Could not open config file."
        }
    }

    func openLog() {
        guard let url = sessionLogStore?.fileURL else {
            lastError = "Session log is unavailable."
            return
        }

        if NSWorkspace.shared.open(url) {
            lastError = nil
        } else {
            lastError = "Could not open session log."
        }
    }

    private func configureStorage() {
        do {
            let configURL = try MiniTimerPaths.pauseConfigFile()
            let logURL = try MiniTimerPaths.sessionLogFile()

            let pauseConfigStore = PauseConfigStore(fileURL: configURL)
            try pauseConfigStore.ensureFileExists()

            let sessionLogStore = SessionLogStore(fileURL: logURL)
            try sessionLogStore.ensureFileExists()

            self.pauseConfigStore = pauseConfigStore
            self.sessionLogStore = sessionLogStore
            lastError = nil
        } catch {
            lastError = "Storage setup failed: \(error.localizedDescription)"
        }
    }

    private func startTicking() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        let focusState = currentFocusState()
        timerStore.tick(focusedApp: focusState.focusedApp, isExcluded: focusState.isExcluded)
        syncPublishedState()
    }

    private func refreshFocusStateForCurrentApp() -> AppFocusInfo? {
        let focusState = currentFocusState()
        timerStore.refreshFocusState(focusedApp: focusState.focusedApp, isExcluded: focusState.isExcluded)
        syncPublishedState()
        return focusState.focusedApp
    }

    private func currentFocusState() -> (focusedApp: AppFocusInfo?, isExcluded: Bool) {
        let focusedApp = focusMonitor.currentApp()

        do {
            try pauseConfigStore?.reloadIfChanged()
        } catch {
            lastError = "Config reload failed: \(error.localizedDescription)"
        }

        let isExcluded = pauseConfigStore?.isExcluded(focusedApp) ?? false
        return (focusedApp, isExcluded)
    }

    private func syncPublishedState() {
        elapsedLabel = timerStore.formattedElapsed
        isRunning = timerStore.isManuallyRunning
        stateLabel = timerStore.state.rawValue
        focusedAppLabel = timerStore.lastFocusedApp?.displayName ?? "unknown"
    }
}

@main
@MainActor
struct MiniTimerApp: App {
    @StateObject private var controller = MiniTimerController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            Button(controller.isRunning ? "Pause" : "Play") {
                controller.togglePlayPause()
            }

            Button("Reset") {
                controller.reset()
            }

            Button("Save") {
                controller.save()
            }

            Divider()

            Text("State: \(controller.stateLabel)")
                .disabled(true)
            Text("Focused: \(controller.focusedAppLabel)")
                .disabled(true)

            Divider()

            Button("Open Config") {
                controller.openConfig()
            }

            Button("Open Log") {
                controller.openLog()
            }

            if let lastError = controller.lastError {
                Divider()
                Text("Last error: \(lastError)")
                    .disabled(true)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Text(controller.elapsedLabel)
                .font(.system(.body, design: .monospaced))
                .monospacedDigit()
                .frame(width: 72, alignment: .leading)
        }
        .menuBarExtraStyle(.menu)
    }
}
