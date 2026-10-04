# X unofficial

An unofficial WebApp for [X](https://x.com) on Ubuntu Touch (Lomiri).
It wraps the mobile X website in a full-screen `WebEngineView` and replaces
X's own navigation with a floating menu.

> This project is not affiliated with, endorsed by, or sponsored by X Corp.

## Features

- **Full-screen web view.** No top bar, so the page uses the whole screen.
- **Floating "X" button** at the bottom centre. Tap it and a fan of shortcuts
  opens with a short animation:
  - **Back**: go to the previous page (dimmed when there is nothing to go back to)
  - **Home**
  - **Explore**
  - **Notifications**
  - **Messages**
  - **Post**
  - **Refresh**: reload the page
- **X's own UI is cleaned up.** The bottom navigation bar and the floating
  "Post" button are hidden, since the menu above replaces them.
- **Edge swipe back.** Swipe from the left edge of the screen to go back.
- **Offline screen.** A simple "no connection" page with a retry button
  instead of the default Chromium error page.
- **Splash screen** with the X logo while the first page loads.
- **File upload.** Photos and videos are picked through the Lomiri Content Hub.
- **Permissions.** Notifications, microphone and camera requests are granted automatically.
- **Persistent login.** Cookies and a 150 MB disk cache are kept between launches.

## Project structure

```
qml/
  Main.qml            Main window, web view, splash, offline screen
  FabMenu.qml         The floating "X" button and its fan menu
  ImportPage.qml      File picker (Content Hub)
  scrollBarTheme.js   Script injected into x.com (hides the X bottom bar and
                      floating Post button, hides scrollbars, edge swipe back,
                      and handles navigation for the menu)
assets/               Logo and splash image
po/                   Translations
manifest.json.in      Click package manifest
instaweb.desktop.in   Desktop entry
instaweb.apparmor     AppArmor profile
clickable.yaml        Clickable build configuration
```

## Building

You need [Clickable](https://clickable-ut.dev/) (7.1.2 or newer).

Run on your desktop:

```
clickable desktop
```

Build and install on a connected device:

```
clickable
```

## Customising

- **Spacing and size of the menu buttons:** `arcRadius` and `itemSize` at the top of `qml/FabMenu.qml`.
- **Menu entries:** the `entries` list in `qml/FabMenu.qml`. The `key` values `back` and `reload`
  are handled directly in `onNavigate` in `qml/Main.qml`. All other keys are
  handled by `window.__xGo` in `qml/scrollBarTheme.js`.
- **Accent colour:** `accentColor` in `qml/Main.qml`.
- **When the menu button is visible:** the `wanted` property on `FabMenu` in
  `qml/Main.qml`. It is always `true` at the moment.

## Notes

X changes its page structure often. The hiding of the bottom bar and the
floating Post button in `scrollBarTheme.js` avoids relying on class names, but
it can still break after a redesign. If one of them reappears, that script is
the place to fix.

## License

GPL-3.0. See the header of each source file.
Copyright (C) 2026 Renzard Politakis
