# Message formatting: in-game verification

Use a copied profile when checking formatting changes.

## Native list parity

1. Open a chat tab's native settings and compare its message entries with Glass's
   Message formatting categories: Player Messages, Creature Messages, Combat,
   PvP, and Other.
2. Check that entries have the same labels and order within each category. Glass
   should not add separate incoming/outgoing Whisper pages or internal message
   types absent from native settings.
3. Check Channels against the native Global Channels list. Joined channels should
   appear in numbered order, including unchecked channels. Empty channel slots
   are not formatting targets. Actual combat-log filters, text-to-speech, and
   Additional Colors are outside this feature.
4. Join, leave, and reorder channels. Their pages should update without opening
   native settings first, and formatting should stay associated with the channel
   rather than its temporary number.

## Grouped formatting

1. Set a body color and background for Whisper, then send and receive whispers.
   Both directions should use the chosen style.
2. Check Emote with both a custom `/emote` and a predefined emote. Both should use
   that entry's formatting.
3. Change Party's alias and color. Party Leader must remain separate. Repeat for
   Raid, Raid Leader, Raid Warning, Instance, and Instance Leader.
4. Check the native Other category's channel notifications separately from normal
   channel messages. On clients with `canaccessvalue` or `issecretvalue` (including
   WoW Forever and Midnight), Glass does not wrap native message handlers to
   recover missing notice metadata. Notices must still appear, but notice-specific
   styles and inferred arrival timestamps can be unavailable when native history
   omits their event metadata. Normal channel messages must retain their styles.
5. If available, check a numbered community channel and the creature/boss and
   battleground entries.

## Saved settings and navigation

1. Open a profile with different existing incoming/outgoing whisper styles.
   The Whisper page should show mixed values without changing either style.
2. Open a mixed body-color picker and dismiss it without editing. Repeat after
   choosing another color using Cancel, Escape, and an outside click. The original
   per-type colors must remain unchanged. Confirm a changed color with Okay and
   check that it applies to every member of the group.
3. Change only the background. Both directions should get that background while
   retaining their different body colors. Reset the group and check both types.
4. Switch profiles, then reload the UI. Saved formatting should remain intact.
5. Leave a channel while its page is selected. Glass should return to an available
   page without errors. Leaving a channel while another settings page is selected
   must not switch away from that page.
6. Rejoin a channel with saved formatting and check that its settings return.

## Native chat taint regression (in-game verification still required)

Reload the UI after installing the fix; an existing insecure hook cannot be
removed from an already-running 2.2.0 session by editing the Lua file alone.

1. On WoW Forever, enable Lua error reporting and receive Party and Party Leader
   messages outside and inside a dungeon/raid, both out of combat and in combat.
   No `ChatFrameOverrides.lua:315` secret-number comparison error attributed to
   Glass should occur. Confirm the messages appear once in the main Glass window
   and in any extra window bound to the same source.
2. Repeat for Raid, Instance, Whisper, and ordinary numbered-channel messages.
   Where available, also check Discord-originated chat. Check native filters,
   temporary whisper windows, and their reuse after closing/reopening.
3. Join and leave a test channel, and receive another player's join/leave notice.
   Confirm native channel selection still controls visibility and no notices are
   lost or duplicated. Expect the notice-formatting limitation described above.
4. Repeat restricted-chat checks on Midnight. On a legacy client without either
   secret-value API, also confirm that notice-specific formatting still works;
   the existing per-frame/global handler hooks remain enabled there.

Syntax checks, luacheck, and source review cannot model the client's taint or
secret-value execution rules. Do not treat their success as an in-game pass.
