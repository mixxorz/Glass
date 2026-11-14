# Optional player identity formatting

## Goal and scope

Add three independent profile-wide options under **Message formatting → Player names**:

- Race icon
- Class icon
- Class-colored names

All default to false. Disabled options preserve native/addon formatting rather than stripping it. Icons precede the sender hyperlink in race/class order, scale with each view's message font, and fade as part of the existing message FontString. No release, version bump, tag, publication, or merge is part of this work.

The user requested autonomous end-to-end delivery in a new worktree. Use the decisions here as implementation assumptions rather than interrupting for staged design/plan approvals. No visual companion is necessary: no unresolved visual choice requires a mockup.

## Approaches considered

1. **Glass render-time formatting (chosen):** retain native accepted messages and metadata, decorate only their sender when rendering. Fits existing profile-wide formatting and extra-window behavior; preserves other displays.
2. Native class-color settings plus a sender-name filter: less parsing, but changes other chat displays, complicates per-profile toggles, and does not reformat existing history cleanly.
3. Event filters/history transformation: can decorate all chat displays, but adds a competing ingestion path and mutates native text. Unnecessary for Glass.

## Architecture

- `MessageFormatting` validates and persists `messageFormatting.players = { raceIcon, classIcon, classColor }`, exposes `GetPlayerSettings()` and `SetPlayerValue(field, value)`, and dispatches existing formatting-change events.
- `MessageMetadata` retains accessible sender name, player GUID, and line ID from native event arguments 2, 12, and 11. Limit enrichment to player-chat event families. Keep optional sender extraction isolated so it cannot discard channel/timestamp metadata.
- A focused `PlayerIdentity` module hides GUID lookup, sex conventions, class colors, atlas aliases/validation, and inline icon markup behind `GetAppearance(guid, options, viewSettings)`. Lookup occurs only when an option is enabled, allowing unavailable information to be retried on a later re-render. No growing global name/GUID cache, roster scan, inspect, or /who request.
- `MessageMarkup:FormatSender(text, message, viewSettings)` uses the existing token scanner to find the first sender hyperlink with a matching native sender identity/line ID. Preserve link targets and delimiters byte-for-byte. Never decorate unrelated player links or Battle.net account names. Restore original color state after the modified label, preserve non-color decorations, and leave the message body unchanged.
- `TextProcessing` runs sender formatting after channel-header formatting, before existing texture alignment and Glass timestamps. Atlas markup includes its own vertical offset because the existing texture processor handles only texture markup.

## APIs and compatibility

Use `GetPlayerInfoByGUID`, whose sex values are 2 (male) and 3 (female). Do not mix these with `Enum.UnitSex` values. Read localization-independent class/race tokens. Validate every inspected value with `Utils.canAccessValue` first.

Use `GetRaceAtlas` / `GetClassAtlas` when present; otherwise construct standard atlas names with race aliases (`scourge → undead`, `highmountaintauren → highmountain`, `lightforgeddraenei → lightforged`, `zandalaritroll → zandalari`). Confirm every atlas with `C_Texture.GetAtlasInfo` (or legacy `GetAtlasInfo`) before emitting `|A` markup. Unknown sex/race or absent atlases omit only the affected icon. Use native class-color data without changing native CVars or per-channel class-color settings.

Secret text bypasses formatting. Secret/missing sender identity, lookup results, or unsupported markup leaves that sender unchanged. Processor errors remain contained by the existing pipeline. Preserve native buffers, records, engine-managed layout, fading, hyperlinks, and scroll anchoring.

## Refresh and history

Use existing global formatting events. Icon toggles request text reprocessing and relayout; class-color changes can request markup-only reprocessing. Existing profile copy/reset/switch notifications apply. Extra windows share the same options but use their own font size/offset. Reprocessing always starts from raw text, so icons never accumulate.

History with trustworthy native event metadata can be decorated. Legacy plain-string history, system messages, NPC messages, and Battle.net account whispers remain unchanged. Unavailable lookup results are not negatively cached.

## Research

- Better Forever Chat 0.14.12: https://www.curseforge.com/wow/addons/better-forever-chat/files/9550558 — inspected by research agent; uses GUID metadata and validated race/class atlases. GPL-3.0-or-later; no implementation code is copied.
- Blizzard sender formatting: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua — `GetDecoratedSenderName`, native class-color behavior and argument ordering.
- GUID API: https://warcraft.wiki.gg/wiki/API:GetPlayerInfoByGUID
- Classic race-atlas helper: https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXML/Classic/SharedUtils.lua
- Atlas markup: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXMLBase/TextureUtil.lua
- Retail chat lockdown declarations: https://github.com/Gethe/wow-ui-source/blob/e97025bc56d4/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua

## Verification

Repository policy prohibits automated tests and test harnesses. Run Lua 5.1-compatible syntax checks, luacheck, whitespace/diff checks, and independent code review. Baseline: all 31 addon Lua files parse under LuaJIT; luacheck 1.2.0 reports zero warnings/errors. Tools/dependencies are local to ignored `libs/.devtools`; addon libraries are copied into this worktree's ignored `libs`.

Manual in-game verification remains required: all eight toggle combinations; live/history/reload/profile switch; own/other-player say, channel, party, guild, emote and both whisper directions; race aliases and both sexes; extra-window font/offset; native precolored names/icons; item/spell/player links in bodies; clicking/right-clicking sender names; fading/wrapping/scroll anchoring; missing metadata; Retail restricted chat. Prepare explicit instructions without claiming in-game verification.
