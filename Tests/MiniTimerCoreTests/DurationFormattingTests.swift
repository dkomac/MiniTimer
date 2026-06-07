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
