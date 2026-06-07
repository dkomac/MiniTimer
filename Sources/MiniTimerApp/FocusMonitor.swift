import AppKit
import MiniTimerCore

struct FocusMonitor {
    func currentApp() -> AppFocusInfo? {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        return AppFocusInfo(
            localizedName: application.localizedName,
            bundleIdentifier: application.bundleIdentifier
        )
    }
}
