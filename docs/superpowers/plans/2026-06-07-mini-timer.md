# Mini Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native SwiftUI macOS menu bar timer with play, pause, reset, save, and automatic pause while configured apps are focused.

**Architecture:** Use a Swift Package with a testable `MiniTimerCore` library target and a small `MiniTimerApp` executable target. The core target owns timer state, duration formatting, pause config parsing, app-support paths, and session log formatting; the app target owns `MenuBarExtra`, focused-app detection through AppKit, and file-opening actions.

**Tech Stack:** Swift 5.9, SwiftUI `MenuBarExtra`, AppKit `NSWorkspace`, XCTest, macOS 13 or newer.

---

## File Structure

- Create `Package.swift`: Swift package manifest for the core library, menu bar executable, and tests.
- Create `Sources/MiniTimerCore/MiniTimerCore.swift`: tiny bootstrap file for the initial scaffold.
- Create `Sources/MiniTimerCore/AppFocusInfo.swift`: shared focused-app value type.
- Create `Sources/MiniTimerCore/DurationFormatting.swift`: `HH:MM:SS` duration formatter.
- Create `Sources/MiniTimerCore/TimerStore.swift`: observable timer state and tick rules.
- Create `Sources/MiniTimerCore/PauseConfigStore.swift`: pause-app config creation, parsing, reload, and matching.
- Create `Sources/MiniTimerCore/SessionLogStore.swift`: app-support path helpers and plain-text session log append behavior.
- Create `Sources/MiniTimerApp/FocusMonitor.swift`: AppKit bridge for `NSWorkspace.shared.frontmostApplication`.
- Create `Sources/MiniTimerApp/MiniTimerApp.swift`: SwiftUI menu bar app, controller, and menu actions.
- Create `Tests/MiniTimerCoreTests/DurationFormattingTests.swift`: duration formatting tests.
- Create `Tests/MiniTimerCoreTests/TimerStoreTests.swift`: timer state tests.
- Create `Tests/MiniTimerCoreTests/PauseConfigStoreTests.swift`: config parsing and matching tests.
- Create `Tests/MiniTimerCoreTests/SessionLogStoreTests.swift`: session log formatting and append tests.

---

### Task 1: Scaffold Swift Package

**Files:**
- Create: `Package.swift`
- Create: `Sources/MiniTimerCore/MiniTimerCore.swift`
- Create: `Sources/MiniTimerApp/MiniTimerApp.swift`

- [ ] **Step 1: Create the package manifest**

Write `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MiniTimerCore", targets: ["MiniTimerCore"]),
        .executable(name: "MiniTimerApp", targets: ["MiniTimerApp"])
    ],
    targets: [
        .target(name: "MiniTimerCore"),
        .executableTarget(
            name: "MiniTimerApp",
            dependencies: ["MiniTimerCore"]
        ),
        .testTarget(
            name: "MiniTimerCoreTests",
            dependencies: ["MiniTimerCore"]
        )
    ]
)
```

- [ ] **Step 2: Create a bootstrap core source file**

Write `Sources/MiniTimerCore/MiniTimerCore.swift`:

```swift
public enum MiniTimerCoreBootstrap {}
```

- [ ] **Step 3: Create a minimal menu bar executable**

Write `Sources/MiniTimerApp/MiniTimerApp.swift`:

```swift
import AppKit
import SwiftUI
import MiniTimerCore

@main
struct MiniTimerApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            Text("Mini Timer")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Label("00:00:00", systemImage: "timer")
        }
        .menuBarExtraStyle(.menu)
    }
}
```

- [ ] **Step 4: Verify the scaffold builds**

Run:

```bash
swift build
```

Expected: build completes successfully.

- [ ] **Step 5: Commit the scaffold**

Run:

```bash
git add Package.swift Sources/MiniTimerCore/MiniTimerCore.swift Sources/MiniTimerApp/MiniTimerApp.swift
git commit -m "feat: scaffold SwiftUI menu bar app"
```

---

### Task 2: Duration Formatting

**Files:**
- Create: `Tests/MiniTimerCoreTests/DurationFormattingTests.swift`
- Create: `Sources/MiniTimerCore/DurationFormatting.swift`

- [ ] **Step 1: Write the failing duration formatting tests**

Write `Tests/MiniTimerCoreTests/DurationFormattingTests.swift`:

```swift
import XCTest
@testable import MiniTimerCore

final class DurationFormattingTests: XCTestCase {
    func testFormatsZeroSeconds() {
        XCTAssertEqual(DurationFormatting.string(from: 0), "00:00:00")
    }

    func testFormatsHoursMinutesAndSeconds() {
        XCTAssertEqual(DurationFormatting.string(from: 3_661), "01:01:01")
    }

    func testFormatsDurationsLongerThanOneDay() {
        XCTAssertEqual(DurationFormatting.string(from: 90_061), "25:01:01")
    }

    func testNegativeDurationsDisplayAsZero() {
        XCTAssertEqual(DurationFormatting.string(from: -12), "00:00:00")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter DurationFormattingTests
```

Expected: FAIL because `DurationFormatting` is not defined.

- [ ] **Step 3: Implement duration formatting**

Write `Sources/MiniTimerCore/DurationFormatting.swift`:

```swift
import Foundation

public enum DurationFormatting {
    public static func string(from totalSeconds: Int) -> String {
        let clampedSeconds = max(0, totalSeconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let seconds = clampedSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
swift test --filter DurationFormattingTests
```

Expected: PASS.

- [ ] **Step 5: Commit duration formatting**

Run:

```bash
git add Sources/MiniTimerCore/DurationFormatting.swift Tests/MiniTimerCoreTests/DurationFormattingTests.swift
git commit -m "feat: add duration formatting"
```

---

### Task 3: Timer State

**Files:**
- Create: `Sources/MiniTimerCore/AppFocusInfo.swift`
- Create: `Sources/MiniTimerCore/TimerStore.swift`
- Create: `Tests/MiniTimerCoreTests/TimerStoreTests.swift`

- [ ] **Step 1: Write the failing timer tests**

Write `Tests/MiniTimerCoreTests/TimerStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter TimerStoreTests
```

Expected: FAIL because `TimerStore`, `TimerRunState`, and `AppFocusInfo` are not defined.

- [ ] **Step 3: Implement focused-app value type**

Write `Sources/MiniTimerCore/AppFocusInfo.swift`:

```swift
public struct AppFocusInfo: Equatable {
    public let localizedName: String?
    public let bundleIdentifier: String?

    public init(localizedName: String?, bundleIdentifier: String?) {
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
    }

    public var displayName: String {
        localizedName ?? bundleIdentifier ?? "unknown"
    }
}
```

- [ ] **Step 4: Implement timer state**

Write `Sources/MiniTimerCore/TimerStore.swift`:

```swift
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

    public func tick(focusedApp: AppFocusInfo?, isExcluded: Bool) {
        lastFocusedApp = focusedApp

        guard isManuallyRunning else {
            isAutoPaused = false
            return
        }

        isAutoPaused = isExcluded

        guard !isExcluded else {
            return
        }

        elapsedSeconds += 1
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
swift test --filter TimerStoreTests
```

Expected: PASS.

- [ ] **Step 6: Commit timer state**

Run:

```bash
git add Sources/MiniTimerCore/AppFocusInfo.swift Sources/MiniTimerCore/TimerStore.swift Tests/MiniTimerCoreTests/TimerStoreTests.swift
git commit -m "feat: add timer state"
```

---

### Task 4: Pause Config Store

**Files:**
- Create: `Sources/MiniTimerCore/PauseConfigStore.swift`
- Create: `Tests/MiniTimerCoreTests/PauseConfigStoreTests.swift`

- [ ] **Step 1: Write the failing pause config tests**

Write `Tests/MiniTimerCoreTests/PauseConfigStoreTests.swift`:

```swift
import XCTest
@testable import MiniTimerCore

final class PauseConfigStoreTests: XCTestCase {
    func testParseIgnoresBlankLinesWhitespaceAndComments() {
        let text = """

        # Pause list
          Safari
        com.apple.Music

        # Done
        """

        XCTAssertEqual(PauseConfigStore.parse(text), ["Safari", "com.apple.Music"])
    }

    func testMatchesAppNameCaseInsensitively() {
        let store = PauseConfigStore(fileURL: temporaryFileURL())
        store.replaceEntriesForTesting(["safari"])

        let app = AppFocusInfo(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")

        XCTAssertTrue(store.isExcluded(app))
    }

    func testMatchesBundleIdentifierExactly() {
        let store = PauseConfigStore(fileURL: temporaryFileURL())
        store.replaceEntriesForTesting(["com.apple.Safari"])

        let app = AppFocusInfo(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")

        XCTAssertTrue(store.isExcluded(app))
    }

    func testBundleIdentifierMatchingIsCaseSensitive() {
        let store = PauseConfigStore(fileURL: temporaryFileURL())
        store.replaceEntriesForTesting(["COM.APPLE.SAFARI"])

        let app = AppFocusInfo(localizedName: nil, bundleIdentifier: "com.apple.Safari")

        XCTAssertFalse(store.isExcluded(app))
    }

    func testEnsureFileExistsCreatesReadableDefaultConfig() throws {
        let fileURL = temporaryFileURL()
        let store = PauseConfigStore(fileURL: fileURL)

        try store.ensureFileExists()

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("Pause while these apps are focused."))
        XCTAssertTrue(contents.contains("Safari"))
    }

    private func temporaryFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniTimer-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("paused-apps.conf")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter PauseConfigStoreTests
```

Expected: FAIL because `PauseConfigStore` is not defined.

- [ ] **Step 3: Implement pause config storage**

Write `Sources/MiniTimerCore/PauseConfigStore.swift`:

```swift
import Foundation

public final class PauseConfigStore {
    public let fileURL: URL

    private let fileManager: FileManager
    private var entries: Set<String>
    private var lastLoadedModificationDate: Date?

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.entries = []
        self.lastLoadedModificationDate = nil
    }

    public func ensureFileExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: fileURL.path) {
            try Self.defaultConfig.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        try reload()
    }

    public func reload() throws {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        entries = Self.parse(text)
        lastLoadedModificationDate = try modificationDate()
    }

    public func reloadIfChanged() throws {
        if !fileManager.fileExists(atPath: fileURL.path) {
            try ensureFileExists()
            return
        }

        let currentModificationDate = try modificationDate()
        if currentModificationDate != lastLoadedModificationDate {
            try reload()
        }
    }

    public func isExcluded(_ app: AppFocusInfo?) -> Bool {
        guard let app else {
            return false
        }

        if let bundleIdentifier = app.bundleIdentifier, entries.contains(bundleIdentifier) {
            return true
        }

        guard let localizedName = app.localizedName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !localizedName.isEmpty else {
            return false
        }

        let lowercasedName = localizedName.lowercased()
        return entries.contains { entry in
            entry.lowercased() == lowercasedName
        }
    }

    public static func parse(_ text: String) -> Set<String> {
        Set(
            text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        )
    }

    func replaceEntriesForTesting(_ entries: Set<String>) {
        self.entries = entries
    }

    private func modificationDate() throws -> Date? {
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        return attributes[.modificationDate] as? Date
    }

    private static let defaultConfig = """
    # Pause while these apps are focused.
    # You can use app names or bundle IDs.
    Safari
    com.apple.Music
    """
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
swift test --filter PauseConfigStoreTests
```

Expected: PASS.

- [ ] **Step 5: Commit pause config storage**

Run:

```bash
git add Sources/MiniTimerCore/PauseConfigStore.swift Tests/MiniTimerCoreTests/PauseConfigStoreTests.swift
git commit -m "feat: add pause config store"
```

---

### Task 5: Session Log Store

**Files:**
- Create: `Sources/MiniTimerCore/SessionLogStore.swift`
- Create: `Tests/MiniTimerCoreTests/SessionLogStoreTests.swift`

- [ ] **Step 1: Write the failing session log tests**

Write `Tests/MiniTimerCoreTests/SessionLogStoreTests.swift`:

```swift
import XCTest
@testable import MiniTimerCore

final class SessionLogStoreTests: XCTestCase {
    func testFormatsSnapshotAsReadableSingleLineEntry() {
        let snapshot = SessionSnapshot(
            date: Date(timeIntervalSince1970: 0),
            elapsedSeconds: 3_661,
            state: .running,
            focusedApp: AppFocusInfo(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")
        )

        let line = SessionLogStore.format(
            snapshot: snapshot,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(
            line,
            "[1970-01-01 00:00:00] elapsed=01:01:01 state=running focused=\"Safari\" bundleID=\"com.apple.Safari\""
        )
    }

    func testFormattingEscapesQuotesInFocusedAppName() {
        let snapshot = SessionSnapshot(
            date: Date(timeIntervalSince1970: 0),
            elapsedSeconds: 1,
            state: .autoPaused,
            focusedApp: AppFocusInfo(localizedName: "Quote \" App", bundleIdentifier: nil)
        )

        let line = SessionLogStore.format(
            snapshot: snapshot,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertTrue(line.contains("focused=\"Quote \\\" App\""))
        XCTAssertTrue(line.contains("bundleID=\"unknown\""))
    }

    func testAppendCreatesFileAndAddsEntries() throws {
        let fileURL = temporaryFileURL()
        let store = SessionLogStore(fileURL: fileURL)
        let first = SessionSnapshot(
            date: Date(timeIntervalSince1970: 0),
            elapsedSeconds: 1,
            state: .running,
            focusedApp: nil
        )
        let second = SessionSnapshot(
            date: Date(timeIntervalSince1970: 60),
            elapsedSeconds: 2,
            state: .manuallyPaused,
            focusedApp: nil
        )

        try store.append(first, timeZone: TimeZone(secondsFromGMT: 0)!)
        try store.append(second, timeZone: TimeZone(secondsFromGMT: 0)!)

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = contents.split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("elapsed=00:00:01"))
        XCTAssertTrue(lines[1].contains("state=manual-paused"))
    }

    func testMiniTimerPathsUseApplicationSupportMiniTimerDirectory() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniTimer-\(UUID().uuidString)", isDirectory: true)
        let directory = try MiniTimerPaths.applicationSupportDirectory(in: baseDirectory)

        XCTAssertEqual(directory.lastPathComponent, "MiniTimer")
    }

    private func temporaryFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniTimer-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("sessions.txt")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter SessionLogStoreTests
```

Expected: FAIL because `SessionSnapshot`, `SessionLogStore`, and `MiniTimerPaths` are not defined.

- [ ] **Step 3: Implement session logging and app-support paths**

Write `Sources/MiniTimerCore/SessionLogStore.swift`:

```swift
import Foundation

public struct SessionSnapshot: Equatable {
    public let date: Date
    public let elapsedSeconds: Int
    public let state: TimerRunState
    public let focusedApp: AppFocusInfo?

    public init(date: Date, elapsedSeconds: Int, state: TimerRunState, focusedApp: AppFocusInfo?) {
        self.date = date
        self.elapsedSeconds = elapsedSeconds
        self.state = state
        self.focusedApp = focusedApp
    }
}

public enum MiniTimerPaths {
    public static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let baseDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try applicationSupportDirectory(in: baseDirectory, fileManager: fileManager)
    }

    public static func applicationSupportDirectory(
        in baseDirectory: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = baseDirectory.appendingPathComponent("MiniTimer", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public static func pauseConfigFile(fileManager: FileManager = .default) throws -> URL {
        try applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("paused-apps.conf")
    }

    public static func sessionLogFile(fileManager: FileManager = .default) throws -> URL {
        try applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("sessions.txt")
    }
}

public final class SessionLogStore {
    public let fileURL: URL

    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func ensureFileExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: fileURL.path) {
            try Data().write(to: fileURL)
        }
    }

    public func append(_ snapshot: SessionSnapshot, timeZone: TimeZone = .current) throws {
        try ensureFileExists()

        let currentContents = try String(contentsOf: fileURL, encoding: .utf8)
        let line = Self.format(snapshot: snapshot, timeZone: timeZone)
        try (currentContents + line + "\n").write(to: fileURL, atomically: true, encoding: .utf8)
    }

    public static func format(snapshot: SessionSnapshot, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let timestamp = formatter.string(from: snapshot.date)
        let elapsed = DurationFormatting.string(from: snapshot.elapsedSeconds)
        let focusedName = quote(snapshot.focusedApp?.localizedName ?? "unknown")
        let bundleIdentifier = quote(snapshot.focusedApp?.bundleIdentifier ?? "unknown")

        return "[\(timestamp)] elapsed=\(elapsed) state=\(snapshot.state.rawValue) focused=\"\(focusedName)\" bundleID=\"\(bundleIdentifier)\""
    }

    private static func quote(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
swift test --filter SessionLogStoreTests
```

Expected: PASS.

- [ ] **Step 5: Run the full core test suite**

Run:

```bash
swift test
```

Expected: PASS for all `MiniTimerCoreTests`.

- [ ] **Step 6: Commit session logging**

Run:

```bash
git add Sources/MiniTimerCore/SessionLogStore.swift Tests/MiniTimerCoreTests/SessionLogStoreTests.swift
git commit -m "feat: add session log store"
```

---

### Task 6: Menu Bar App Integration

**Files:**
- Create: `Sources/MiniTimerApp/FocusMonitor.swift`
- Modify: `Sources/MiniTimerApp/MiniTimerApp.swift`

- [ ] **Step 1: Create the focused-app monitor**

Write `Sources/MiniTimerApp/FocusMonitor.swift`:

```swift
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
```

- [ ] **Step 2: Replace the minimal app with the integrated app**

Write `Sources/MiniTimerApp/MiniTimerApp.swift`:

```swift
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

        let snapshot = SessionSnapshot(
            date: Date(),
            elapsedSeconds: timerStore.elapsedSeconds,
            state: timerStore.state,
            focusedApp: timerStore.lastFocusedApp
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

        NSWorkspace.shared.open(url)
    }

    func openLog() {
        guard let url = sessionLogStore?.fileURL else {
            lastError = "Session log is unavailable."
            return
        }

        NSWorkspace.shared.open(url)
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
        let focusedApp = focusMonitor.currentApp()

        do {
            try pauseConfigStore?.reloadIfChanged()
        } catch {
            lastError = "Config reload failed: \(error.localizedDescription)"
        }

        let isExcluded = pauseConfigStore?.isExcluded(focusedApp) ?? false
        timerStore.tick(focusedApp: focusedApp, isExcluded: isExcluded)
        syncPublishedState()
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
            Label(controller.elapsedLabel, systemImage: "timer")
        }
        .menuBarExtraStyle(.menu)
    }
}
```

- [ ] **Step 3: Build the integrated app**

Run:

```bash
swift build
```

Expected: build completes successfully.

- [ ] **Step 4: Run all tests**

Run:

```bash
swift test
```

Expected: PASS for all `MiniTimerCoreTests`.

- [ ] **Step 5: Commit menu bar integration**

Run:

```bash
git add Sources/MiniTimerApp/FocusMonitor.swift Sources/MiniTimerApp/MiniTimerApp.swift
git commit -m "feat: integrate menu bar timer"
```

---

### Task 7: Manual Verification

**Files:**
- No file changes.

- [ ] **Step 1: Launch the app from the package**

Run:

```bash
swift run MiniTimerApp
```

Expected: a timer item appears in the macOS menu bar with label `00:00:00`.

- [ ] **Step 2: Verify play and pause**

In the menu bar app:

```text
Open menu -> Play -> wait three seconds -> Open menu -> Pause
```

Expected: the menu bar label increases while running and stops increasing while paused.

- [ ] **Step 3: Verify reset**

In the menu bar app:

```text
Open menu -> Reset
```

Expected: the menu bar label returns to `00:00:00`.

- [ ] **Step 4: Verify save keeps running**

In the menu bar app:

```text
Open menu -> Play -> wait three seconds -> Open menu -> Save
```

Expected: the menu bar label keeps increasing after Save.

Then run:

```bash
tail -n 1 "$HOME/Library/Application Support/MiniTimer/sessions.txt"
```

Expected: output matches this shape:

```text
[YYYY-MM-DD HH:MM:SS] elapsed=00:00:03 state=running focused="Terminal" bundleID="com.apple.Terminal"
```

- [ ] **Step 5: Verify config-driven auto-pause**

Run:

```bash
printf "Terminal\n" > "$HOME/Library/Application Support/MiniTimer/paused-apps.conf"
```

With Terminal focused and the timer running, wait three seconds.

Expected: the timer label does not increase while Terminal is focused. Switch focus to another app that is not listed in the config.

Expected: the timer label starts increasing again.

- [ ] **Step 6: Stop the manually launched app**

In the menu bar app:

```text
Open menu -> Quit
```

Expected: `swift run MiniTimerApp` exits in the terminal.

- [ ] **Step 7: Capture final status**

Run:

```bash
git status --short
```

Expected: no uncommitted changes.
