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
        let expectedDirectory = baseDirectory.appendingPathComponent("MiniTimer", isDirectory: true)
        let directory = try MiniTimerPaths.applicationSupportDirectory(in: baseDirectory)

        XCTAssertEqual(directory, expectedDirectory)
    }

    private func temporaryFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniTimer-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("sessions.txt")
    }
}
