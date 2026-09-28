# Multiple-window in-game checks

These checks require WoW. Lua parsing and linting cannot verify native frame
layout, secure hooks, mouse propagation, or chat delivery.

## Home page

- After `/reload`, `/glass` should open Home with the original compact Info layout:
  version beside What's New, then command hints beside Unlock. List `/glass`,
  `/glass lock`, and `/glass demo`, with each description on the same line as its
  command. Keep `/glass unlock` undocumented. The Demo mode checkbox should sit
  below Info, without a large heading, Quick actions box, or bottom tip.
  Check the default 780 × 500 dialog size and resize it: controls should remain
  accessible without overlap.
- Unlock must show the existing movers; What's New must open the release notes.
  Both `/glass lock` and its undocumented `/glass unlock` alias should still unlock
  without redirecting an already-open settings page to Home.
- Visit an extra window or Profiles, close settings, then run `/glass`: it must
  return to Home. Creating an extra window must still open that new window's
  settings directly. Ordinary slider changes must not redirect to Home.

## Global demo mode

- Turn on Demo mode on Home. Main and all enabled extras should immediately show
  sample history with a gold [Demo] prefix on every line. Even an extra window
  with an unavailable source should show samples; disabled extras should not.
- Confirm that new samples arrive every 2.5 seconds, using each window's normal
  animation and fading. Check class-colored names, loot links, inline money icons,
  and the long party message's wrapping. Each window should retain its own styling.
- Scroll one window up while the others stay at the bottom. The next sample
  should show that window's unread button; jumping down should behave as it does
  with real messages. Hover, scroll, and hyperlink settings must still apply,
  including Non-interactive mode and windows with hidden tab bars.
- Switch main tabs during the demo. Ordinary tabs should show samples, while
  Combat Log stays native. Unlock and resize windows; adjust styles live.
- Add, disable, re-enable, and delete extras while demo mode is on. New and
  re-enabled extras should join the demo with current sample history. Disabled
  and deleted views must stop receiving samples. Repeat with pooled windows.
- Change an extra's source, rename or close its source tab, and receive real
  messages during the demo. Samples should continue without resetting that
  window's scrollback. Turn demo mode off: each view should return to its current
  real source, including real messages received during the demo. Unavailable
  sources should become unavailable again; disabled views should remain disabled.
- Toggle with `/glass demo` while Home is open and check that the checkbox tracks
  the state. Toggle repeatedly and wait: there should be only one sample stream,
  and no samples should arrive after turning demo mode off.
- With demo mode active, switch, copy, and reset profiles, and run `/reload`.
  Each action should end demo mode. No sample messages should remain in native
  history or return on a later reload. Typing must still send real chat normally;
  the preview itself must never send messages to anyone.

## Existing behavior

- Load an existing Glass profile. Confirm the main window keeps its position,
  dimensions, fonts, gradients, input styling, and selected chat tab.
- Send messages using Enter, slash commands, and whisper replies. Shift-click an
  item into the input. Confirm main input focus does not reveal extra windows.
- Switch main tabs, including Combat Log. Open and close whisper conversation
  windows. Check for Lua errors and duplicate messages.
- After a fresh `/reload`, select Combat Log: its filter toolbar must sit below
  the Glass tabs, and General must remain clickable. Repeat after changing tab
  font size and vertical padding. Move the mouse away and back to verify that
  tab fading and reveal still work, then switch back to General.

## Message delivery after the routing refactor

- After `/reload`, check that Main shows existing history before receiving a new
  message. New messages should appear once, with the same colors and animation.
- Have two extra windows follow Loot while Main shows General. Receive loot,
  then select Loot in Main. All three views should show the message once, and
  selecting the tab must not reset either extra window's scroll position.
- Disable one extra window while messages arrive. The other views must keep
  updating. Re-enable it: it should show current history immediately, without
  replaying incoming animations. Repeat with deletion and recreation.
- Change an extra window's source while messages are arriving. No pending
  messages from the previous source should appear afterward. A source rename
  or style change must not reload history or lose the current scroll position.
- Open, close, and reopen whisper popouts with copied history. Check history
  order and new-message delivery, including after a native frame slot is reused.
  Extras following a closed source must stay unavailable until reassigned.
- Where the client loads older chat history, check that it appears above existing
  messages in chronological order and preserves the visible scroll position.
- Switch profiles while messages arrive. Removed views must stop updating; the
  new profile's views should show their own sources without duplicates.
- Confirm that Combat Log remains native and switching back restores normal chat.

## Create, configure, and remove

- After `/reload`, open Main and an extra window's settings. Each tab should show
  labeled sections within the page, not another row of tabs or extra tree nodes.
  Check Size, Position, and Window actions; Text, Background, and Layout in
  Messages, Tab bar, and Main's Chat input; and Behavior's Fading and animation
  and Mouse interaction. Font, leading, wrapping, and text-icon offset belong
  under Text; opacity and gradients under Background; padding, tab spacing, and
  input positioning under Layout. All controls must remain reachable by scrolling
  at the default settings-window size.
- Main's tabs must appear as Window, Messages, Tab bar, Chat input, Behavior;
  extras must keep Behavior last and have no Chat input tab. In Main → Chat input
  → Layout, change Horizontal padding from 0 to 100 while typing. The channel
  label and input should remain aligned, and a narrow input with a long whisper
  target should retain room to type. Message and tab-bar padding must not change.
- Start from a profile that has no explicit tab-gradient widths: its existing
  tab gradients must look unchanged after `/reload`. Change Messages' left and
  right gradient widths; neither Tab bar value nor its appearance should follow.
  Change tab gradients and verify Messages remains unchanged. Repeat after a
  profile switch, copy, and reset; existing explicit tab widths must be preserved.
- Drag sliders inside these sections, change an extra window's tab font size and
  show/hide its tab bar, then check its minimum Height. Rename, change source,
  unlock, and delete through the grouped controls to verify their callbacks.
- Create a Loot-filtered chat tab. Add one Glass view from its right-click menu
  and another through Windows → Add window. Combat Log must not be offered.
- Switch the main interface away from Loot. Both extra views must still receive
  each loot message once. Reload with General selected and Loot docked but
  unselected: Loot must remain available in the source selector, and unlocking
  its extra view must not show “Unavailable”. Changing the source of one view
  must not affect the other.
- With an extra Loot view open, select Loot in the main tab bar. The main view
  must show its existing loot history too, including after a reload and after
  the messages have faded. Switch back to General: the extra Loot view must stay
  unchanged. Repeat without an extra view and verify each new loot message
  appears once in every view that follows Loot.
- Open a whisper popout that is selected automatically. Its main Glass renderer
  must appear immediately, including any history copied into the conversation.
- Change fonts, backgrounds, padding, gradients, and fade timings independently
  on both extra views and Main. Existing lines must resize without overlap.
- With existing multi-line messages visible, toggle Indent on line wrap off and
  on in Main and an extra window. Existing text must reflow immediately, without
  needing a new message or reload. Check line heights, hyperlinks, colored text,
  and the next incoming message; also repeat while viewing older scrollback.
- Check slider drag ranges: font sizes 8–32; window width 100–1200 and height
  60–600 (or its tab-bar minimum); X/Y position ±2000/±1000; input offset ±100;
  line padding 0–1; tab vertical padding 0–20; tab spacing 0–50; gradient widths
  1–300; fade delay 1–60 seconds; fades 0–3 seconds; slide-in 0–1 second.
  Existing values outside these soft ranges must remain unchanged on opening
  settings or reloading. Manual entry should still accept values within the
  original hard limits. Large tab fonts/padding must keep Height's slider at or
  above the required minimum without interrupting dragging.
- In Messages, set left padding to 0 and right padding to 60, then reverse them.
  Verify text alignment and wrapping in Main and each extra window independently;
  tab-bar and input padding must stay unchanged. An existing profile must initially
  retain its old horizontal padding on both sides. Reload and confirm asymmetric
  padding persists. Resize narrowly with large padding: text width must stay positive.
- Drag message and tab background-opacity sliders continuously without releasing
  the mouse, for Main and an extra window. The thumb must keep tracking and the
  background must update live without rebuilding the settings panel. Repeat for
  Main's input opacity and the gradient-width sliders; changing backgrounds must
  not reset scrollback or cancel an in-progress scroll animation.
- Repeat continuous dragging for an extra window's font size, padding, fade
  duration, width, height, and position, both locked and unlocked. Each control
  must track until mouse release. Reload and confirm the values persist and
  Main's settings are unchanged. Moving/resizing an unlocked extra window must
  not rebuild an open settings panel.
- After live slider changes, rename an extra window and change its tab font size
  or padding. The settings tree name and minimum window height must still update
  correctly, and adding or deleting windows must still refresh the tree.
- Enable an extra view's tab bar. Verify its source name, font, padding, gradients,
  and hover/fade behavior. Hiding it should reclaim the space above messages.
- Disable a view, receive messages, then re-enable it. Its available source
  history should be restored without playing an incoming animation for every line.
- Rename the source tab. Close it, then create a different tab in its place.
  The view should retain its settings and show Source tab unavailable, not follow
  the replacement automatically. Explicitly choosing a replacement should work.
- Delete one extra view. Its source and other views must remain usable. Repeat
  creation/deletion to exercise pooled views and confirm old messages do not leak.

## Interaction and layout

- Scroll one view up while another remains at the bottom. Receive new messages;
  only the scrolled view should show its unread cue. Jumping down must not change
  any other view's scroll position.
- Disable hover, scrolling, and links separately. Also test hover disabled with
  scrolling enabled: scrolling can reveal history, but messages should still fade.
- Enable Non-interactive and verify clicks and mouse-wheel input reach the game,
  including over item links and where the jump button would normally be.
- Hover an item tooltip, then disable interactions or delete its window. The
  tooltip must not remain stuck open.
- Use both `/glass lock` and `/glass unlock`. Move and resize Main and each extra,
  including disabled, empty, unavailable, and non-interactive windows. Lock all
  windows; confirm independent geometry persists after `/reload`.
- Change main tab spacing and font size with several short and long tab names.
  Test overflow, selecting the rightmost tab, reordering, resizing, and resetting
  spacing to zero. Zero must leave no added gap between labels; horizontal padding
  should only inset the bar's outer edges. All labels and the selected tab should
  remain accessible.

## Message edge fades

The message viewport uses a regular `Frame` with clipped children, and moves
its content with `SetPoint`, following
[Blizzard's ScrollBox implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua).
`SetClipsChildren(true)` also enables the render-layer flattening required by
[`SetAlphaGradient`](https://warcraft.wiki.gg/wiki/API:Frame_SetAlphaGradient).
The viewport enables flattening explicitly as well.

- After `/reload`, verify Main and pre-existing extra windows default to 14px for
  both edge-fade controls under Messages → Layout. Change them independently
  between 0 and 40, then reload and switch/copy/reset profiles. Saved zeroes must
  stay disabled; fresh/reset profiles should use the defaults.
- Fill the pane with messages: text, inline icons, links, and backgrounds should
  fade to transparent at the top rather than darkening the world behind them.
  At the latest message, the bottom line must remain fully visible. Scroll up:
  the bottom edge should fade too. Set only one edge to zero and check the other.
- The fade boundaries must stay at the pane edges during wheel scrolling and
  incoming-message animation. Test Main and extras with and without tab bars.
  Change either slider while scrolled up or jumping: the view must not jump,
  reload history, lose unread state, or interrupt the drag/animation.
- Tabs, chat input, movers, the jump button, and its unread glow must not inherit
  the message-edge gradients. Links and wheel scrolling must still work, including
  over faded text. Hidden links beyond the pane edges must not show tooltips or
  intercept clicks. Test hover/scroll/link toggles and full non-interactive mode.
- Check empty panes, short histories, and histories longer than the pane. Latest
  messages must stay bottom-aligned, scrolling to the oldest message must not
  expose the blank buffer above it, and incoming messages must retain their slide
  animation. While viewing history, change font size and resize the pane; it must
  not scroll into empty space. Test incoming messages after the 128-message limit.
- Jump to latest: keep the lower fade during the transition, remove it on arrival,
  and preserve clipping throughout. Interrupt with the wheel or receive messages
  mid-jump. Resize very short: gradients must not overlap past the pane midpoint.
- Delete/recreate extras and temporary chat windows to exercise pooled renderers;
  their old gradients must not leak. Combat Log must remain native and unchanged.
  On a client without frame alpha-gradient support, controls should be disabled
  and chat should continue working without errors.

## Jump-to-latest appearance

- Scroll up: confirm a dark, rounded, 90%-opaque button centered horizontally,
  10 pixels above the bottom, with the visible down arrow centered beside
  “Jump to latest message”.
- Receive a message while scrolled up: confirm the label becomes “Jump to latest
  unread messages” and a gold glow surrounds only the button. There should be no
  horizontal line or glow across the bottom of the window.
- Jump down: the button and glow should disappear, and messages must stay clipped
  to the window until the scroll finishes. Repeat in an extra window, with
  different font sizes, a narrow width, and its tab bar on and off.
- Receive messages during the jump: the view should reach the latest message
  without briefly exposing content below the window. Interrupt with the mouse
  wheel, resize, or change the source mid-jump; no old completion callback should
  move the view or restore the wrong clipping height.

## Profiles and characters

- Switch, copy, and reset Glass profiles while extras exist. Old views must
  disappear and the selected profile's views and styles must load correctly.
- Use a shared profile on another character whose chat tabs differ. Sources must
  remain unassigned until explicitly selected; layouts and styles should carry over.
- Reload with regular sources and an automatically opened whisper source. Regular
  sources should reconnect if their identity still matches; the whisper source
  must not attach to a recycled conversation slot.
