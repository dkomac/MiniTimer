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
