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
        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))
    }

    func testReloadIfChangedLoadsExistingFileOnFirstCall() throws {
        let fileURL = temporaryFileURL()
        try writeConfig("Safari\n", to: fileURL)
        let store = PauseConfigStore(fileURL: fileURL)

        try store.reloadIfChanged()

        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))
    }

    func testReloadIfChangedDoesNotReloadUnchangedFile() throws {
        let fileURL = temporaryFileURL()
        try writeConfig("Safari\n", to: fileURL)
        let store = PauseConfigStore(fileURL: fileURL)

        try store.reloadIfChanged()
        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))

        store.replaceEntriesForTesting(["Injected"])
        try store.reloadIfChanged()

        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Injected", bundleIdentifier: nil)))
        XCTAssertFalse(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))
    }

    func testReloadIfChangedReloadsChangedFile() throws {
        let fileURL = temporaryFileURL()
        let oldDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newerDate = Date(timeIntervalSince1970: 1_700_000_100)
        try writeConfig("Safari\n", to: fileURL, modificationDate: oldDate)
        let store = PauseConfigStore(fileURL: fileURL)

        try store.reloadIfChanged()
        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))

        try writeConfig("Music\n", to: fileURL, modificationDate: newerDate)
        try store.reloadIfChanged()

        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Music", bundleIdentifier: nil)))
        XCTAssertFalse(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))
    }

    func testReloadIfChangedRecreatesMissingFile() throws {
        let fileURL = temporaryFileURL()
        let store = PauseConfigStore(fileURL: fileURL)

        try store.reloadIfChanged()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(store.isExcluded(AppFocusInfo(localizedName: "Safari", bundleIdentifier: nil)))
    }

    private func temporaryFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniTimer-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory.appendingPathComponent("paused-apps.conf")
    }

    private func writeConfig(_ text: String, to fileURL: URL, modificationDate: Date? = nil) throws {
        try text.write(to: fileURL, atomically: true, encoding: .utf8)

        if let modificationDate {
            try FileManager.default.setAttributes(
                [.modificationDate: modificationDate],
                ofItemAtPath: fileURL.path
            )
        }
    }
}
