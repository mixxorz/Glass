# 2.0.0 (2026-11-05)

Glass 2.0 brings the changes from the 1.9 and 2.0 alphas to the stable release.

New features

- Add extra chat windows with independent source tabs, styles, layout, scrollback, and mouse-interaction settings.
- Add drag-to-resize controls while windows are unlocked with `/glass lock`.
- Add demo mode on Home and `/glass demo` to preview styles and animations without changing real chat history.
- Add configurable message and tab gradients, fonts, padding, spacing, and top/bottom message fades.
- Add separate transition controls for messages, tab bars, and the edit box, plus Never fade out options for messages and tab bars.
- Add configurable Alt-arrow editing and grouped chat-input settings under Edit box.
- Restore Blizzard's chat menu, Chat Channels button, and movable Social/Friends widget with independent visibility settings.

Improvements

- Update client compatibility for Retail (Midnight), WoW Forever, Classic Era/Hardcore, Burning Crusade Anniversary, and Mists of Pandaria Classic.
- Reorganize settings around Home and individual windows.
- Add a circular jump-to-latest button with an unread glow and a Glass icon in WoW's AddOn List and Home settings.
- Mouse wheel scrolls per message; use Shift+Scroll to move within long messages.
- Reduce layout work during profile changes, large history restorations, and incoming message bursts.

Bug fixes

- Fix errors caused by secret chat text during boss encounters and other restricted content. Secret messages retain Glass's styling and fades; incoming batches containing secret text skip sliding.
- Support multilingual text with native font families; custom fonts apply to Latin text.
- Fix Classic chat-tab initialization, optional chat-button startup errors, and duplicate temporary-window allocation.
- Preserve native chat-input handlers and fix Prat Editbox hook errors. Prat's Editbox module must still be disabled to avoid layout and visibility conflicts.
- Fix empty custom chat tabs, Combat Log toolbar overlap, message rewrapping, slider dragging, and messages appearing below the window when jumping to the latest message.
- Fix missing or invalid fonts leaving chat text without a usable font.
