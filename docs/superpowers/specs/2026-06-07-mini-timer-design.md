# Mini Timer Design

## Goal

Build a native macOS menu bar timer app. The app shows elapsed time in the top menu bar and supports play, pause, reset, and save. It can automatically pause counting while configured apps are focused.

## Scope

Version 1 is a menu bar-only app with no regular Dock window by default. A future settings or history window should be easy to add, so timer state, storage, focused-app detection, and UI should stay separated.

## User Experience

The menu bar item displays elapsed time as `HH:MM:SS`. Opening the menu shows controls for:

- Play or pause the timer manually.
- Reset the timer to zero.
- Save the current elapsed time and date without stopping or resetting the timer.
- Open the pause-app config file.
- Open the saved sessions log.

When the current frontmost app matches the pause config, the timer remains visually available but elapsed time does not increase. Manual pause still takes priority over automatic behavior.

## Pause Config

The app reads a plain text config file from:

`~/Library/Application Support/MiniTimer/paused-apps.conf`

If the file does not exist, the app creates it with comments and examples. Each non-empty, non-comment line is treated as either an app name or a bundle ID. Matching is case-insensitive for app names and exact for bundle IDs after trimming whitespace.

Example:

```text
# Pause while these apps are focused.
# You can use app names or bundle IDs.
Safari
com.apple.Music
```

The app checks the config file modification date on each tick and reloads only when the file has changed, so users can edit the file without restarting the app.

## Saved Sessions

Pressing Save appends a timestamped snapshot to:

`~/Library/Application Support/MiniTimer/sessions.txt`

Save does not stop or reset the timer. A log entry should include at least:

- Local date and time.
- Current elapsed duration.
- Whether the timer was manually paused, auto-paused, or running.
- The focused app at the time of save when available.

The log uses a readable plain text format rather than a database. This keeps version 1 simple and easy to inspect manually.

Log entry format:

```text
[2026-06-07 09:41:12] elapsed=00:12:34 state=running focused="Safari" bundleID="com.apple.Safari"
```

## Architecture

Use a native SwiftUI macOS app with `MenuBarExtra` as the primary UI.

Suggested units:

- `TimerStore`: owns elapsed time, manual running state, auto-pause state, and tick behavior.
- `FocusMonitor`: reads `NSWorkspace.shared.frontmostApplication` and exposes the current app name and bundle ID.
- `PauseConfigStore`: creates, reads, parses, and reloads `paused-apps.conf`.
- `SessionLogStore`: creates the Application Support directory and appends save entries to `sessions.txt`.
- `MenuBarView`: renders the elapsed time and menu actions, calling into the stores.

`TimerStore` should only increment elapsed time when the user has started the timer and the focused app is not excluded. It should not own file paths or UI details.

## Data Flow

On launch, the app creates the Application Support directory, ensures the config and log files are available, loads pause rules, and starts the timer tick loop.

On each tick:

1. `FocusMonitor` identifies the frontmost app.
2. `PauseConfigStore` determines whether that app should trigger auto-pause.
3. `TimerStore` advances elapsed time only if it is manually running and not auto-paused.
4. The menu bar label updates from the current elapsed value.

On Save, `SessionLogStore` appends the current timer snapshot and the timer keeps running.

On Reset, `TimerStore` returns elapsed time to zero. Reset does not automatically write a log entry in version 1.

## Error Handling

File creation and append failures should not crash the app. The menu should show a disabled "Last error" line when the config or log file cannot be accessed.

If focused-app information is unavailable, the app should keep counting unless manually paused. Missing bundle IDs should not prevent app-name matching.

## Testing

Unit tests should cover:

- Timer advancement rules for running, manual pause, and auto-pause.
- Pause config parsing for comments, whitespace, app names, and bundle IDs.
- Save log formatting and append behavior.

Manual verification should cover:

- The app appears in the macOS menu bar.
- Play, pause, reset, and save work from the menu.
- Editing `paused-apps.conf` affects auto-pause behavior.
- `sessions.txt` receives entries without stopping the timer.
