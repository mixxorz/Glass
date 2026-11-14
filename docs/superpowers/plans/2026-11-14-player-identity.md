# Player Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional race/class icons and class-colored player names without changing native chat settings or Glass fading.

**Architecture:** Extend existing validated formatting settings and accepted-message metadata. Resolve appearance behind a focused module, then change only the verified native sender slot in Glass's existing text pipeline.

**Tech Stack:** Lua 5.1, WoW chat/player/texture APIs, AceDB/AceConfig.

## Global Constraints

- All three options default to false. Disabled options preserve native/addon formatting rather than stripping it.
- No release, version bump, tag, publication, or merge is part of this work.
- Repository policy prohibits automated tests and test harnesses.
- Secret text bypasses formatting. Secret/missing sender identity, lookup results, or unsupported markup leaves that sender unchanged.
- Preserve native buffers, records, engine-managed layout, fading, hyperlinks, and scroll anchoring.
- Extra windows share the same options but use their own font size/offset.
- No implementation code is copied from Better Forever Chat.

## File responsibilities

- `Glass/init.lua`: module registration and profile defaults.
- `Glass/Modules/MessageFormatting.lua`: validated settings API and refresh notifications.
- `Glass/Modules/ConfigMessageFormatting.lua`: three concise toggles on a Player names page.
- `Glass/Modules/MessageMetadata.lua`: accessible native sender metadata only.
- `Glass/Modules/PlayerIdentity.lua` (new): best-effort GUID lookup, class colors and validated icon markup.
- `Glass/Modules/MessageMarkup.lua`: sender-slot parsing and label-only color replacement.
- `Glass/Modules/TextProcessing.lua`: sender processor insertion.
- `Glass.toc`: load new module before markup processing.
- `Glass/Components/SlidingMessageFrame.lua`: invalidate generated icon markup on font-size/window reset changes (review-discovered integration requirement).
- `Glass/Components/MessageLine.lua`: invalidate cached public height after markup-only reprocessing, since lookup availability can change embedded icon widths.
- `README.md`, `docs/player-identity-testing.md`: feature documentation and manual verification.

## Static check commands

Run from `.worktrees/player-identity`:

```sh
/opt/homebrew/bin/luajit -e 'for path in io.popen("find Glass -name \"*.lua\""):lines() do assert(loadfile(path)) end; print("All addon Lua files parse (LuaJIT/Lua 5.1).")'
LUA_PATH='libs/.devtools/luacheck-src/src/?.lua;libs/.devtools/luacheck-src/src/?/init.lua;libs/.devtools/argparse/src/?.lua;;' LUA_CPATH='libs/.devtools/?.so;;' /opt/homebrew/bin/luajit libs/.devtools/luacheck-src/bin/luacheck.lua Glass
git diff --check
```

Expected: all addon files parse; zero lint warnings/errors; no whitespace errors. No in-game behavior may be claimed from these checks.

### Task 1: Profile settings and configuration

**Files:** Modify `Glass/init.lua`, `Glass/Modules/MessageFormatting.lua`, `Glass/Modules/ConfigMessageFormatting.lua`.

**Interfaces:** Produce `Formatting:GetPlayerSettings()` returning `{ raceIcon = boolean, classIcon = boolean, classColor = boolean }`; `Formatting:SetPlayerValue(field, value)` accepts known fields and booleans/nil. Runtime task consumes these.

- [x] Add `players = { raceIcon = false, classIcon = false, classColor = false }` alongside timestamps in defaults.
- [x] Read settings through existing `container`/`public` helpers, returning true only for accessible true booleans. Add validated setter, rejecting unknown fields and secret/non-boolean values; nil removes override. Preserve other saved fields.
- [x] Notify global formatting changes: icon toggles use existing text refresh; classColor uses markup refresh. Do not repurpose timestamp `color` validation.
- [x] Add `Player names` page at order 0.5 (timestamps stays 0); toggles ordered Race icon, Class icon, Class-colored names. Use `GetPlayerSettings` / `SetPlayerValue`, no direct DB mutation. One scope description is allowed: `Icons appear when character information is available.` No redundant help copy.
- [x] Run static checks, self-review settings/profile/extra-window compatibility, commit only task files. Report command/output and concerns.

### Task 2: Sender metadata, appearance lookup, and safe rendering

**Files:** Create `Glass/Modules/PlayerIdentity.lua`; modify `Glass/init.lua` (registration only), `Glass.toc`, `Glass/Modules/MessageMetadata.lua`, `Glass/Modules/MessageMarkup.lua`, `Glass/Modules/TextProcessing.lua`.

**Interfaces:** Consume `Formatting:GetPlayerSettings()`. Produce `PlayerIdentity:GetAppearance(guid, options, viewSettings, expectedName)` returning `{ icons = string, color = RGB-table-or-nil }` or nil. Produce `Markup:FormatSender(text, message, viewSettings)` returning string. Metadata fields: `senderName`, `senderGUID`, `senderLineID`, `senderFlag` (all accessible).

- [x] Register/load PlayerIdentity before MessageMarkup. Keep metadata extraction independently protected from existing channel/timestamp decoding.
- [x] Accept native SAY/YELL/WHISPER/WHISPER_INFORM/PARTY/PARTY_LEADER/PARTY_GUIDE/RAID/RAID_LEADER/RAID_WARNING/GUILD/OFFICER/INSTANCE_CHAT/INSTANCE_CHAT_LEADER/EMOTE/CHANNEL only. Extract args2/12/11/6 from packed extraData event args, requiring matching `CHAT_MSG_` event, accessible nonempty name, `Player-` GUID, positive integer lineID, and accessible string flag. Exclude NPCs, system, Battle.net, Discord/community links, TEXT_EMOTE and legacy plain strings.
- [x] `GetAppearance` looks up GUID with pcall only when an option is enabled. Guard returned class/race/sex/name/realm independently. If a returned name is available and disagrees with expectedName, return nil (including outgoing-whisper ambiguity). If expectedName includes a realm, compare normalized realms when returned realm is available. No unit scanning or persistent growing cache.
- [x] Build race atlas with GetRaceAtlas when available, otherwise standard aliases and `raceicon-<race>-<sex>`; feature-detect helpers. Build class atlas with GetClassAtlas or `classicon-<class>`. Validate atlas with C_Texture.GetAtlasInfo or legacy GetAtlasInfo under protected calls. Missing assets omit only affected icon.
- [x] Emit standard inline atlas markup `|A:<atlas>:<height>:<width>:0:<offsetY>|a`, using view messageFontSize (default profile), baseline offset matching existing iconTextureYOffset semantics, and race/class order with one space after each emitted icon. Validate numeric view settings before formatting. Use RAID_CLASS_COLORS/C_ClassColor data for color, not CVars. Unknown sex omits race icon. Guard every result before string operations/indexing/comparison.
- [x] Extend the existing markup token scanner, not blind gsub/search. Find the first non-channel hyperlink in the native header and verify exact name, line ID and normalized chat category against metadata. Categories: WHISPER_INFORM→WHISPER, PARTY_LEADER/PARTY_GUIDE→PARTY, RAID_LEADER/RAID_WARNING→RAID, INSTANCE_CHAT_LEADER→INSTANCE_CHAT. Never scan onward into the body after an unexpected first link.
- [x] Validate the sender-slot prefix against the localized `CHAT_<chatType>_GET` template before its first `%s` (or `%1$s`). Ignore color/reset/decoration tokens and the single verified leading channel-header link in prefix comparison; allow native CHAT_FLAG_<senderFlag> text. Whitespace may be normalized. Reject unknown text, malformed markup, extra links, missing templates and ambiguous placeholders. This prevents body links to the same sender/context from becoming replacement candidates.
- [x] Preserve hyperlink target/delimiters byte-for-byte. Insert generated icons immediately before the sender link. For class coloring, remove only color/reset controls inside the sender label, preserve text and icons, and restore original post-label color state so body/outer wrappers remain unchanged. Abort on nested/malformed links. Repeated rendering starts from raw text and cannot accumulate decorations.
- [x] Insert sender processor after headerProcessor and before textureProcessor. Existing processor pcall contains failures. Do not modify router/layout/fade code.
- [x] Run static checks, self-review parsing/color/secret-value paths, commit task files. Report exact outputs and in-game limitations.

### Task 3: Review and prepare in-game verification

**Files:** Modify `README.md`; create `docs/player-identity-testing.md`; update plan checkboxes.

- [x] Document settings location, defaults, availability limitation and preserved fading concisely.
- [x] Write concrete in-game steps for all toggle combinations, profile changes, history/reload, multiple views/font sizes/offsets, standard chat types/whisper directions, NPC/BN/system exclusions, native colors/icons, item/player links, wrapping/fading/scroll anchoring, aliases/sex variants and Retail restricted chat. Record that in-game verification is pending.
- [x] Request broad independent whole-branch review against spec and plan; resolve findings and re-review fixes. Verify settings refresh in unchanged renderer/profile code explicitly.
- [x] Run all static checks, check TOC dependencies and git status, commit docs/fixes. Leave branch/worktree intact, unmerged and unreleased.
- [x] Report branch/path, how to enable settings, checks performed, research limitation, and readiness for in-game testing. Do not change any WoW installation symlink unless requested; installation modifies a path outside this project.

## Execution record

- Settings task: `1c07f23`, spec and quality review approved.
- Rendering task: `6d8131e`, followed by reviewed fixes in `7448127` for atlas helper arguments/aliases, independent realm checks, and font-size invalidation.
- Documentation: `f69a3cf`; final review fix `b8624bb` clears cached message heights after markup reprocessing and removes documentation trailing whitespace.
- Whole-branch review and fix re-review: no remaining concrete findings; ready for in-game testing only.
- Static verification: 32 addon Lua files parse; luacheck 1.2.0 reports zero warnings/errors. Extended check: 79 addon/library Lua files parse. TOC/XML dependency audit: zero missing paths. Branch-wide whitespace check clean after fixes.
- In-game behavior remains unverified. No automated tests/harnesses, installation changes, release/version/tag/push/merge operations.
