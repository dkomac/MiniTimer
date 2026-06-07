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
