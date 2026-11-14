# Player identity: in-game verification

Branch: `feat/player-identity`

Worktree: `.worktrees/player-identity`

Status: **In-game verification pending.** Static checks and review do not establish client behavior.

## Setup

1. Install this worktree using the existing Glass addon symlink in the requested WoW client. Do not copy files or replace a real addon directory without confirmation. This task does not change the installation automatically.
2. Ensure the worktree has its addon libraries in `libs/`, then reload the UI.
3. Enable Lua errors (`/console scriptErrors 1`). If available, use BugSack/BugGrabber to record errors.
4. Open `/glass` → **Chat options** and find the **Player names** section below **Timestamps**. All three player-name options should initially be off in a new profile.
5. Use real player chat, not `/glass demo`: demo samples do not carry native sender identity. Have another player of a different race/class available, ideally on another realm.

## Options and live refresh

For each row, check say, party/guild or channel chat, and both whisper directions. Change settings while these messages are still visible and while scrolled up.

| Race icon | Class icon | Class-colored names | Expected added formatting |
|---|---|---|---|
| Off | Off | Off | None; native formatting remains |
| On | Off | Off | Race icon |
| Off | On | Off | Class icon |
| Off | Off | On | Name in class color |
| On | On | Off | Race, then class icon |
| On | Off | On | Race icon and class-colored name |
| Off | On | On | Class icon and class-colored name |
| On | On | On | Both icons and class-colored name |

- Only the player-name label should change color, not the channel label or message body.
- Icons should appear immediately before the clickable name. Repeatedly toggling, scrolling, or changing tabs must not accumulate icons.
- If Blizzard already class-colors a name, disabling the Glass option should restore that incoming appearance, not force a channel color.
- Turn each setting on/off, switch/copy/reset profiles, and reload. Confirm defaults, persistence, and immediate refresh.
- Confirm timestamp enable/format/color controls work in the same Chat options page, and previous timestamp/player-name settings survive the navigation move.
- Confirm Message formatting contains only type/channel overrides. With a custom channel selected, leave it and clear its final saved override; selection should return to Message formatting without targeting the removed Timestamps page.

## Chat and identity

- Send/receive SAY, YELL, PARTY and leader, RAID and leader/warning, GUILD, OFFICER, INSTANCE_CHAT and leader, a custom channel, and an ordinary `/e` emote where available. Unavailable chat types can be marked not applicable.
- For outgoing whispers, confirm the icon/color belongs to the **recipient**, not your own character. A missing/ambiguous lookup must produce no added formatting rather than the wrong character.
- Include same-realm and cross-realm characters, both supported sex values, and races with atlas aliases (Undead, Highmountain Tauren, Lightforged Draenei, Zandalari Troll where supported).
- Check AFK/DND names and any available guide/newcomer/GM decorations. Native flags/icons should remain intact. Unsupported transformed headers may be left unchanged.
- System messages, NPC chat, Battle.net account names, community/Discord names, and text emotes without a conventional sender header should remain unchanged.

## Links and formatting boundaries

- Left-click, Shift-click, and right-click sender names: normal whisper/name-insertion/context-menu behavior should remain.
- Send messages containing item, spell, and player links—including a link to the sender. Body links must remain untouched and clickable.
- Check messages with escaped pipe characters, raid-target icons, native timerunning icons, and precolored sender labels from another addon.
- Enable channel aliases, label colors, body colors, and Glass timestamps. They must work independently from player appearance; no color should leak after the name.
- Check another chat addon with name-formatting features enabled. Record any unsupported header shapes or duplicate external icons rather than assuming universal compatibility.

## Layout, history, and fading

- Send a message long enough to wrap. Icons should scale with the message font without excessive line height or clipping.
- In a narrow window with race/class icons enabled, scroll up and jump to bottom to populate cached heights. Scroll up again, then toggle only class-colored names after character info becomes available or unavailable, so reprocessing adds or removes icons. Check wrapping and jump to bottom again: the animation distance and final bottom alignment should match the refreshed text, without clipping or gaps. Repeat for both availability changes.
- Create an extra Glass window with a different message font size and icon offset. It should share these toggles but render icons at its own size/alignment.
- Adjust icon vertical offset, font size, leading, and frame width. Check the baseline, wrapped height, scroll anchor, and bottom alignment.
- Let messages fade completely, then reveal them by hovering. Icons and names must fade/reappear with their messages; there should be no persistent standalone icon frames.
- Scroll through live and restored history, switch tabs/windows, and reload. Native history with sender metadata should be eligible; plain legacy/addon strings may remain undecorated.

## Retail restricted chat

On Retail Midnight, repeat with chat-messaging lockdown active as available in the client. Secret message text and sender information must display through the existing native path without added formatting or Lua errors. Combat lockdown alone is not proof that chat-messaging lockdown is active.

## Record results

Record client/build, race/class, option combination, enabled chat addons, observed result, and any Lua error stack. Distinguish **passed**, **failed**, **not applicable**, and **not exercised**. In particular, report icon availability per supported client; source research cannot confirm installed atlas assets.
