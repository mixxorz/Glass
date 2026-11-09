# Changelog

## Unreleased

New features

- Customize channel labels, text colors, and message backgrounds under Message formatting.
- Add native timestamp functionality, with 12 or 24 hour formats, seconds, and a color customization.
- Customizable chat channel aliases like `[1]` for General, `[G]` for Guild, and so on.
- Preview message formatting with `/glass demo`.

Changes

- Chat labels are shortened by default, such as `[Guild]` to `[G]`; customize or disable this in Message formatting.
- Native timestamps replace WoW's built-in timestamps.

Bug fixes

- Fix extra messages appearing in restored chat history.

## 2.0.0 (2026-11-05)

Glass 2.0 brings the changes from the 1.9 and 2.0 alphas to the stable release.

### New features

* Add extra chat windows with independent source tabs, styles, layout, scrollback, and mouse-interaction settings
* Add drag-to-resize controls while windows are unlocked with `/glass lock`
* Add demo mode on Home and `/glass demo` to preview styles and animations without changing real chat history
* Add configurable message and tab gradients, fonts, padding, spacing, and top/bottom message fades
* Add separate transition controls for messages, tab bars, and the edit box, plus Never fade out options for messages and tab bars
* Add configurable Alt-arrow editing and grouped chat-input settings under Edit box
* Restore Blizzard's chat menu, Chat Channels button, and movable Social/Friends widget with independent visibility settings

### Improvements

* Update client compatibility for Retail (Midnight), WoW Forever, Classic Era/Hardcore, Burning Crusade Anniversary, and Mists of Pandaria Classic
* Reorganize settings around Home and individual windows
* Add a circular jump-to-latest button with an unread glow and a Glass icon in WoW's AddOn List and Home settings
* Mouse wheel scrolls per message; use Shift+Scroll to move within long messages
* Reduce layout work during profile changes, large history restorations, and incoming message bursts

### Bug fixes

* Fix errors caused by secret chat text during boss encounters and other restricted content. Secret messages retain Glass's styling and fades; incoming batches containing secret text skip sliding
* Support multilingual text with native font families; custom fonts apply to Latin text
* Fix Classic chat-tab initialization, optional chat-button startup errors, and duplicate temporary-window allocation
* Preserve native chat-input handlers and fix Prat Editbox hook errors. Prat's Editbox module must still be disabled to avoid layout and visibility conflicts
* Fix empty custom chat tabs, Combat Log toolbar overlap, message rewrapping, slider dragging, and messages appearing below the window when jumping to the latest message
* Fix missing or invalid fonts leaving chat text without a usable font

## 2.0.0-alpha5 (2026-10-14)

### Changes

* Mouse wheel now scrolls per message; use Shift+Scroll to move within long messages
* Secret messages retain Glass's styling and fades; incoming batches containing secret text skip sliding
* Secret text skips Glass's icon-offset adjustment and Glass-added Prat timestamps

### Bug fixes

* Fix Lua errors caused by secret chat text during boss encounters and other restricted content (#166)
* Preserve ordinary-message slide animations when secret messages remain in history

## 2.0.0-alpha4 (2026-10-11)

### New features

* Add configurable Alt-arrow editing (#128)
* Add separate Transitions controls for messages, tab bars, and the edit box, including zero-duration support
* Add Never fade out options for messages and tab bars (#125)

### Improvements

* Move chat input settings to Edit box and remove redundant per-window unlock actions

### Bug fixes

* Support multilingual text with native font families; custom fonts apply to Latin text (#146)

## 2.0.0-alpha3 (2026-10-10)

### New features

* Add Blizzard's chat/language menu and Chat Channels button to the left of the first Main chat tab, sized to fit the tab bar and kept visible while the chat menu is open
* Add independent show/hide settings for the chat menu, Chat Channels, and Social buttons under Main's Tab bar settings; Chat Menu and Social are on by default, while Chat Channels is off
* Restore Blizzard's Social/Friends and Quick Join widget with an independent position saved per profile; move it with `/glass lock` (#142)

### Improvements

* Replace the jump-to-latest text button with a circular down-arrow button in the bottom-right of Main and extra message panes, retaining the unread glow (#158)
* Add a gold Glass icon to WoW's AddOn List and Home settings
* Refresh the README with the current demo, supported clients, and feature overview

## 2.0.0-alpha2 (2026-10-10)

### Improvements

* Add Classic Era/Hardcore, Burning Crusade Anniversary, and Mists of Pandaria Classic interface versions

### Bug fixes

* Fixed a Lua error when Prat's Editbox module hooks the chat input (#160). The module must still be disabled to avoid layout and visibility conflicts.
* Fixed chat tabs failing to initialize because of Classic texture names and native script-hook collisions
* Fixed startup errors when optional chat buttons or toast frames are absent
* Fixed Glass replacing Blizzard's chat-input show handler
* Fixed duplicate temporary-window allocation when Blizzard returns an existing conversation window
* Reduced repeated message layout work during profile changes and unnecessary render passes after frame hitches
* Fixed large history restorations and message bursts laying out all queued lines in one update
* Fixed missing or invalid fonts leaving chat text without a usable font

## 2.0.0-alpha1 (2026-10-10)

### New features

* Add extra chat windows with independent source tabs, styles, layout, scrollback, and mouse-interaction settings
* Add drag-to-resize controls while windows are unlocked with `/glass lock`
* Add configurable top and bottom fades to transparent for messages
* Add global demo mode on Home and `/glass demo` to preview styles and animations with sample chat without changing real history

### Improvements

* Add separate message and tab gradient controls, left/right message padding, and chat-input padding
* Add configurable tab fonts, padding, and spacing
* Reorganize settings around Home and individual windows, with grouped controls and practical slider drag ranges
* Redesign the jump-to-latest button with an unread glow

### Bug fixes

* Fixed custom chat tabs appearing empty despite having message history
* Fixed Combat Log's filter toolbar overlapping the chat tabs
* Fixed existing messages not rewrapping when changing wrapped-line indentation
* Fixed settings sliders stopping mid-drag while applying changes
* Fixed messages briefly appearing below the window when jumping to the latest message

## 1.9.0-alpha1 (2026-09-26)

* Update Glass for WoW Forever (1.60) and Midnight (12.1)
* Adapt chat tabs, gradients, fonts, mover controls, and hover behavior to current UI APIs
* Midnight compatibility has not yet been verified in-game

## 1.8.0 (2020-10-14)

* Updated for Shadowlands

## 1.7.0 (2020-09-29)

* Add line indention support

## 1.6.0 (2020-09-23)

* Refactor gradient backgrounds (#109)
* Refactor scroll overlay (#109)
* Refactor new message alert (#109)
* Refactor OnUpdate handler (#109)
* Fix GMOTD not displaying (#110)
* Add support for Prat's history module (#100)

## 1.5.0 (2020-09-14)

* Add more customization options (#107)
* Add in-game changelog (#108)

## 1.4.2 (2020-09-09)

* Fix icons not sliding up (#99)
* Fix messages not being displayed sometimes (#99)
* Fix issues with scrolling after frame resize (#99)

## 1.4.1 (2020-09-08)

* Fix AceDB issues

## 1.4.0 (2020-09-07)

* Add classic support (#95)

## 1.3.0 (2020-09-06)

* Add support for third-party chat links (#90)
* Improve scrolling behavior (#92)
* Force chatStyle to classic (#94)

## 1.2.1 (2020-09-01)

* Fix conflict with ElvUI Mover

## 1.2.0 (2020-08-31)

* Major rearchitecture (#79)
* Add support for new tab whisper mode (#80)

## 1.1.1 (2020-08-26)

* Fix text processing pipeline (#70)
* Fix jittery animations (#71)
* Fix dependency issues (#72)

## 1.1.0 (2020-08-24)

* Add "Unlock Window" option to context menu - SammyJames
* Add support for Prat timestamps

## 1.0.1 (2020-08-22)

* Fix Battle.net toast position
* Fix some icon textures being squished

## 1.0.0 (2020-08-22)

* Initial release
