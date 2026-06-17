# DropKit App Store Submission Draft

## App Basics

- App name: `DropKit Clipboard`
- Subtitle: `Menu bar shelf and clipboard history`
- Primary category: `Utilities`
- Platform: `macOS`
- Target version: `1.0.6`
- Bundle ID: `com.dropkit.DropKit`
- SKU: `dropkit-macos-1`
- Review status: Submitted for App Review on 2026-06-10

## Description

DropKit is a lightweight macOS menu bar utility for quick file staging and clipboard history.

Use the floating shelf to hold files temporarily while you work, then drag them out when you need them. Keep recent clipboard items close at hand, search them instantly, and pin the ones you reuse often.

DropKit focuses on fast access, low overhead, and native macOS behavior for everyday multitasking.

## Keywords

`clipboard,menu bar,files,shelf,productivity,drag and drop`

## What's New in 1.0.6

- More reliable watched-folder monitoring, with safeguards against stale file reports.
- Smarter thumbnail memory handling that releases cached images under system memory pressure.
- Smoother shelf scrolling and selection with lazy-loaded thumbnails.
- General stability and performance improvements.

## Permissions

DropKit does **not** use macOS Accessibility features and does **not** request Accessibility permission. The optional shake-to-show-shelf gesture is implemented with standard global mouse-event monitoring (`NSEvent.addGlobalMonitorForEvents` for mouse-drag events), which per AppKit documentation does not require Accessibility access. The only entitlements are App Sandbox and user-selected file read/write (for the optional watched-folder feature).

## Review Notes

- DropKit is a menu bar app for temporary file staging and clipboard history.
- The app does **not** use Accessibility features and does **not** request Accessibility permission.
- The optional shake-to-show-shelf gesture observes global mouse-drag events via `NSEvent.addGlobalMonitorForEvents` (mouse events only), which per AppKit documentation does not require Accessibility access.
- Core features: menu bar access, keyboard shortcuts (via in-app shortcut recorder), clipboard history, and user-selected watched folders.
- The Mac App Store version does not include an external updater or GitHub download flow.
- Watched folders are user-selected explicitly through an open panel and stored using sandbox-compatible bookmarks.

## App Privacy Draft

Current draft based on the local codebase:

- Data collection: `No data collected`
- Rationale:
  - clipboard history is stored locally on device
  - clipboard entries from common password managers are skipped by default, and password-manager concealed pasteboard types are ignored
  - watched-folder access is user-selected and local
  - no analytics, crash SDK, or third-party telemetry is currently integrated

Re-check this section after any future SDK or network integration.

## URLs To Prepare

Hosted on GitHub Pages (gh-pages branch of this repo), independent of the xiaochens.com homepage migration:

- Support URL: `https://chenyuxiaojin.github.io/DropKit/support.html`
- Privacy Policy URL: `https://chenyuxiaojin.github.io/DropKit/privacy.html`

Both are static pages (source in `docs/app-store/web/`). The privacy page states clearly that DropKit collects no data; the support page lists a contact email for user issues. To update them, edit the source and run `docs/app-store/web/deploy.sh`.

## Screenshot Plan

- Menu bar main menu
- Clipboard history panel with search
- Floating shelf in collapsed state
- Floating shelf in expanded state
- Settings window showing shortcuts and watched-folder configuration
