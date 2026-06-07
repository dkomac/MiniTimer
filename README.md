# Mini Timer

Mini Timer is a small native macOS menu bar timer. It shows the elapsed time directly in the menu bar, starts counting when launched, and lets you pause, reset, and save timestamped timer snapshots.

## Run

From this repo:

```bash
swift run MiniTimerApp
```

The timer appears in the macOS menu bar as fixed-width text, for example `00:03:12`.

## Controls

Click the menu bar timer to open the menu:

- `Pause` / `Play`: stop or resume counting.
- `Reset`: set elapsed time back to `00:00:00`.
- `Save`: append the current session snapshot to the log without stopping the timer.
- `Open Config`: open the focused-app auto-pause config.
- `Open Log`: open the saved session log.
- `Quit`: stop the app.

## Auto-Pause Config

Mini Timer can stop counting while specific apps are focused. The config file is created automatically at:

```text
~/Library/Application Support/MiniTimer/paused-apps.conf
```

Each non-empty, non-comment line can be either an app name or a bundle ID:

```text
# Pause while these apps are focused.
# You can use app names or bundle IDs.
Safari
com.apple.Music
Terminal
```

The app reloads this file automatically while running.

## Save Log

Saved sessions are appended to:

```text
~/Library/Application Support/MiniTimer/sessions.txt
```

Each log line includes the save timestamp, exact elapsed time, timer state, focused app, bundle ID, and a readable duration suffix:

```text
[2026-06-07 11:24:00] elapsed=03:23:12 state=running focused="Xcode" bundleID="com.apple.dt.Xcode" - 3h 23m
```

## Tests

Run the test suite with:

```bash
swift test
```

