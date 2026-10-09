# Unreleased

What's new

- Add extra Glass windows for individual Blizzard chat tabs, including Loot. Each has its own styles, position, size, scrollback, and optional source-tab label. Typing still uses Main's chat input.
- Create extra windows from settings or a chat tab's right-click menu. Use `/glass lock` to move and resize all windows, then click Lock when finished.
- Add per-window hover, scrolling, and link controls, plus a fully non-interactive mode.
- Add independent message and tab gradients, left/right message padding, chat-input padding, and tab fonts and spacing.
- Add top and bottom fades to transparent for message text, icons, and backgrounds. Set either fade to 0 to turn it off; the bottom fade goes away at the latest message.
- Reorganize settings around Home and individual windows, with grouped controls and practical slider drag ranges.
- Refresh the jump-to-latest button with an unread glow.
- Add Demo mode on Home and `/glass demo`. Preview styles and animations with sample history and incoming messages. Turning it off restores current real chat; samples are never sent or added to Blizzard history. Reloading or changing profiles also ends the demo.

Bug fixes

- Restore custom-tab history and keep extra windows updating when their source tab is not selected.
- Improve source renaming, closed and reused tabs, and temporary conversation handling.
- Keep Combat Log's filter toolbar below the Glass tabs.
- Reflow existing messages when changing wrapped-line indentation.
- Keep settings sliders responsive and messages clipped during jumps to the latest message.
