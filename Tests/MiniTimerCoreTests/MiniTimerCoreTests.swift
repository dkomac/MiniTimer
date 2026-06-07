import XCTest
@testable import MiniTimerCore

final class MiniTimerCoreTests: XCTestCase {
    func testBootstrapTypeExists() {
        _ = MiniTimerCoreBootstrap.self
    }
}
