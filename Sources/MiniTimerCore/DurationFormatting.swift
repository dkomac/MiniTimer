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
