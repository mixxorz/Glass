# 2.0.0-alpha2 (2026-10-10)

Improvements

- Add Classic Era/Hardcore, Burning Crusade Anniversary, and Mists of Pandaria Classic interface versions.

Bug fixes

- Fixed a Lua error when Prat's Editbox module hooks the chat input (#160). The module must still be disabled to avoid layout and visibility conflicts.
- Fixed chat tabs failing to initialize because of Classic texture names and native script-hook collisions.
- Fixed startup errors when optional chat buttons or toast frames are absent.
- Fixed Glass replacing Blizzard's chat-input show handler.
- Fixed duplicate temporary-window allocation when Blizzard returns an existing conversation window.
- Reduced repeated message layout work during profile changes and unnecessary render passes after frame hitches.
- Fixed large history restorations and message bursts laying out all queued lines in one update.
- Fixed missing or invalid fonts leaving chat text without a usable font.
