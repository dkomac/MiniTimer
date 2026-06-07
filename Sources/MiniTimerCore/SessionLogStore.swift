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
