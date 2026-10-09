# Changelog

## Unreleased

### What's new

* Add display-only extra windows that mirror Blizzard chat tabs, including Loot, with independent styles, layout, and scrollback
* Create extra windows from settings or a chat tab's right-click menu; optionally show the source tab's name above messages
* Move and resize Main and extra windows together with `/glass lock`, including disabled and non-interactive windows
* Add per-window hover, scrolling, and link controls, plus a fully non-interactive mode
* Add independent message and tab gradients, left/right message padding, chat-input padding, and tab fonts and spacing
* Fade message text, icons, and backgrounds to transparent at the pane edges, with separate top and bottom controls
* Reorganize settings around Home and individual windows, with grouped controls and practical slider drag ranges
* Redesign the jump-to-latest button with an unread glow
* Add a global Demo mode checkbox on Home and `/glass demo` to preview styles and animations with sample chat without changing real history

### Fixes and internal changes

* Restore custom chat-tab history and keep extra windows updating when their source tab is not selected
* Handle source renames, closed or reused chat tabs, and temporary conversation windows without silently retargeting extra windows
* Keep Combat Log's filter toolbar below the Glass tabs
* Reflow existing messages when changing wrapped-line indentation
* Keep live settings sliders responsive and improve clipping during jumps to the latest message
* Standardize message records and independent source subscriptions for Main, extra windows, and demo mode
* Document message delivery and in-game verification; add focused routing checks

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
