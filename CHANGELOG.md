# Changelog

## 2.2.0 (2026-11-16)

### New features

- Add optional race icons, class icons, and class-colored player names, all off by default.

### Changes

- Move Glass settings to Settings → AddOns → Glass. `/glass` opens the same panel.
- Move timestamps and player-name settings to Chat options.
- Match Message formatting categories and entries to WoW's native chat settings,
  with shared controls for grouped message types.
- Expand the unlocked Social mover to cover the icon and Battle.net notification area.

### Bug fixes

- Make Battle.net notifications follow the Social icon, with the toast's bottom-left
  corner aligned to the icon's bottom-right corner.

## 2.1.0 (2026-11-11)

### New features

- Customize channel labels, text colors, and message backgrounds under Message formatting.
- Add native timestamp functionality, with 12 or 24 hour formats, seconds, and a color customization.
- Customizable chat channel aliases like `[1]` for General, `[G]` for Guild, and so on.
- Preview message formatting with `/glass demo`.

### Changes

- Chat labels are shortened by default, such as `[Guild]` to `[G]`; customize or disable this in Message formatting.
- Native timestamps replace WoW's built-in timestamps.

### Bug fixes

- Fix extra messages appearing in restored chat history.

## 2.0.0 (2026-11-05)

### New features

- Add extra chat windows with independent source tabs, styles, layout, scrollback, and mouse-interaction settings.
- Add drag-to-resize controls while windows are unlocked with `/glass lock`.
- Add demo mode on Home and `/glass demo` to preview styles and animations without changing real chat history.
- Add configurable message and tab gradients, fonts, padding, spacing, and top/bottom message fades.
- Add separate transition controls for messages, tab bars, and the edit box, plus Never fade out options
  for messages and tab bars.
- Add configurable Alt-arrow editing and grouped chat-input settings under Edit box.
- Restore Blizzard's chat menu, Chat Channels button, and movable Social/Friends widget
  with independent visibility settings.

### Changes

- Update client compatibility for Retail (Midnight), WoW Forever, Classic Era/Hardcore,
  Burning Crusade Anniversary, and Mists of Pandaria Classic.
- Reorganize settings around Home and individual windows.
- Add a circular jump-to-latest button with an unread glow and a Glass icon in WoW's AddOn List and Home settings.
- Mouse wheel scrolls per message; use Shift+Scroll to move within long messages.
- Reduce layout work during profile changes, large history restorations, and incoming message bursts.

### Bug fixes

- Fix errors caused by secret chat text during boss encounters and other restricted content.
  Secret messages retain Glass's styling and fades; incoming batches containing secret text skip sliding.
- Support multilingual text with native font families; custom fonts apply to Latin text.
- Fix Classic chat-tab initialization, optional chat-button startup errors, and duplicate temporary-window allocation.
- Preserve native chat-input handlers and fix Prat Editbox hook errors. Prat's Editbox module must still be disabled
  to avoid layout and visibility conflicts.
- Fix empty custom chat tabs, Combat Log toolbar overlap, message rewrapping, slider dragging,
  and messages appearing below the window when jumping to the latest message.
- Fix missing or invalid fonts leaving chat text without a usable font.

## 1.8.0 (2020-10-14)

### Changes

- Updated for Shadowlands.

## 1.7.0 (2020-09-29)

### New features

- Add line indention support.

## 1.6.0 (2020-09-23)

### New features

- Add support for Prat's history module (#100).

### Changes

- Refactor gradient backgrounds (#109).
- Refactor scroll overlay (#109).
- Refactor new message alert (#109).
- Refactor OnUpdate handler (#109).

### Bug fixes

- Fix GMOTD not displaying (#110).

## 1.5.0 (2020-09-14)

### New features

- Add more customization options (#107).
- Add in-game changelog (#108).

## 1.4.2 (2020-09-09)

### Bug fixes

- Fix icons not sliding up (#99).
- Fix messages not being displayed sometimes (#99).
- Fix issues with scrolling after frame resize (#99).

## 1.4.1 (2020-09-08)

### Bug fixes

- Fix AceDB issues.

## 1.4.0 (2020-09-07)

### New features

- Add classic support (#95).

## 1.3.0 (2020-09-06)

### New features

- Add support for third-party chat links (#90).

### Changes

- Improve scrolling behavior (#92).
- Force chatStyle to classic (#94).

## 1.2.1 (2020-09-01)

### Bug fixes

- Fix conflict with ElvUI Mover.

## 1.2.0 (2020-08-31)

### New features

- Add support for new tab whisper mode (#80).

### Changes

- Major rearchitecture (#79).

## 1.1.1 (2020-08-26)

### Bug fixes

- Fix text processing pipeline (#70).
- Fix jittery animations (#71).
- Fix dependency issues (#72).

## 1.1.0 (2020-08-24)

### New features

- Add "Unlock Window" option to context menu - SammyJames.
- Add support for Prat timestamps.

## 1.0.1 (2020-08-22)

### Bug fixes

- Fix Battle.net toast position.
- Fix some icon textures being squished.

## 1.0.0 (2020-08-22)

### New features

- Initial release.
