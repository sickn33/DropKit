**English** | [中文文档](README.zh-CN.md)

# DropKit

> DropKit is a macOS menu bar utility with a shake-to-summon floating file shelf and a searchable clipboard history.

[![Download on the Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/dropkit-clipboard/id6778846792)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg)
![Version](https://img.shields.io/badge/version-1.0.6-green.svg)

![DropKit demo](DropKit/demo.gif)

---

## Why DropKit?

Moving files between apps on macOS has always been awkward: open Finder, arrange windows, drag across — all while losing your place in the app you were using. DropKit solves this with a floating shelf you summon by shaking your mouse mid-drag, so you never need to break your workflow. A persistent clipboard history panel pairs with the shelf so copied text, images, and files are always a keystroke away.

---

## Features

### Floating File Shelf
- Shake your mouse left-right while dragging a file to summon the shelf instantly
- Drop files onto the shelf for temporary staging; drag them out to any destination when ready
- Grid and list view modes
- Collapses to a compact overlay; expand to see all staged files

### Clipboard History
- Automatic clipboard monitoring — text, images, files, and URLs are captured as you copy
- Full-text search across your history
- Pin important items so they are never pushed out
- Press Space to quick-look the selected item
- Configurable item limit and retention period (Settings → Clipboard)
- Respects password-manager concealed-type entries and an app blacklist — those are never saved

### Menu Bar Integration
- Persistent menu bar icon for instant access
- Global keyboard shortcuts work from any app
- Runs as a background agent (no Dock icon)

---

## Quick Start / Installation

### Download from the Mac App Store (recommended)

**[Download DropKit Clipboard on the Mac App Store](https://apps.apple.com/app/dropkit-clipboard/id6778846792)** — the simplest way to install, with automatic updates. Requires macOS 14.0 (Sonoma) or later. DropKit works out of the box and does **not** require Accessibility or any other special permission.

### Build from Source (for developers)

DropKit is open source. To build it yourself:

| Requirement | Version |
|-------------|---------|
| macOS | 14.0 (Sonoma) or later |
| Xcode | 15.0 or later |
| XcodeGen | latest (`brew install xcodegen`) |

```bash
git clone https://github.com/chenyuxiaojin/DropKit.git
cd DropKit/DropKit
xcodegen generate          # generates DropKit.xcodeproj from project.yml
xcodebuild -scheme DropKit -configuration Release build
```

The built `.app` appears in `build/Release/DropKit.app`. Move it to `/Applications` and launch.

---

## Usage

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Toggle Shelf | `⌘⇧S` |
| Open Clipboard History | `⌘⇧V` |
| Open Settings | `⌘,` |
| Quit | `⌘Q` |

### Shelf

- **Summon**: Shake your mouse left-right while dragging a file
- **Add files**: Drop files onto the shelf while it is visible
- **Use files**: Drag files out of the shelf to any destination
- **Expand view**: Click the expand button to see all staged files
- **Keyboard**: Press `⌘⇧S` at any time to show or hide the shelf

### Clipboard History

- **Open**: Click the menu bar icon → "Clipboard History", or press `⌘⇧V`
- **Paste an item**: Click it or press Return
- **Search**: Type to filter items in real time
- **Preview**: Press Space to Quick Look the selected item
- **Pin**: Right-click → Pin (pinned items are never auto-deleted)
- **Delete**: Right-click → Delete

---

## Compared to Alternatives

| Feature | DropKit | Yoink | Dropover | Maccy | Paste |
|---------|---------|-------|----------|-------|-------|
| Floating file shelf | Yes | Yes | Yes | — | — |
| Shake-to-summon shelf | Yes | — | — | — | — |
| Clipboard history | Yes | — | — | Yes | Yes |
| Shelf + clipboard in one app | Yes | — | — | — | — |
| Menu bar icon | Yes | Yes | Yes | Yes | Yes |
| Local storage, no cloud sync | Yes | Yes | Yes | Yes | No |
| Price | Free (open source) | Paid | Paid | Free | Subscription |

> Note: Feature comparisons are based on publicly available product information as of 2026. Verify current feature sets before making purchasing decisions.

---

## FAQ

**Does DropKit need Accessibility or any special permission?**

No. DropKit works without Accessibility permission. The shake-to-summon shelf detects mouse-drag movement using standard global mouse-event monitoring (`NSEvent.addGlobalMonitorForEvents` for mouse-drag events), which macOS allows without any special permission. DropKit does not read screen content or control other apps.

**How do I summon the shelf?**

Two ways: (1) while actively dragging a file, shake your mouse left-right a few times — the shelf appears automatically; (2) press `⌘⇧S` from any app.

**Where is my clipboard data stored? Is there a privacy mode?**

All clipboard history is stored locally on your Mac at `~/Library/Application Support/DropKit/clipboard_history.json`. No data is sent to any server. DropKit skips items from apps on your configured blacklist (Settings → Clipboard → Excluded Apps) and respects the `org.nspasteboard.ConcealedType` flag used by password managers — those items are never recorded.
Common password managers are also skipped by default, even before you add any custom excluded apps.

**How do I install DropKit?**

The easiest way is to [download it from the Mac App Store](https://apps.apple.com/app/dropkit-clipboard/id6778846792). Prefer to build it yourself? Clone the repo, run `xcodegen generate` then `xcodebuild`, and move the resulting `DropKit.app` to `/Applications`. See [Build from Source](#build-from-source-for-developers) above for full steps.

**Can I set a limit on how many items the clipboard history keeps?**

Yes. Open **Settings → Clipboard** to configure the maximum item count and the retention period (in days). Set either value to 0 to keep items indefinitely. Pinned (favorited) items are exempt from automatic cleanup.

---

## Requirements

- macOS 14.0 (Sonoma) or later
- No special permissions required

---

## License

MIT License — see [LICENSE](LICENSE) for details.
