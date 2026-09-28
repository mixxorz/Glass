# Message delivery

`MessageRouter` connects message sources to renderers. Main and extra windows
subscribe independently; Main does not forward messages to extras.

## Message records

Each record contains unprocessed `text` and RGB fields `r`, `g`, and `b`.
Batches are ordered from oldest to newest. Sources may share records between
subscribers, so renderers must not modify them. `MessageLine` applies text
processing using its own window's settings.

Renderers accept three operations:

- `AppendMessages(messages)` queues new messages for the next render tick.
- `PrependMessages(messages)` queues older history before the existing messages.
- `ReplaceMessages(messages)` clears existing messages, pending deliveries, and
  scroll state, then displays the supplied history without an incoming animation.

The existing renderer still owns layout, animations, fading, unread state, and
its 128-message limit.

## Sources and subscriptions

`CreateSource(readHistory)` takes a function that returns the current history.
`Bind(renderer, source)` replaces that renderer's history and subscribes it to
future deliveries. Binding the same source again does nothing. Binding `nil`
keeps the view registered with no real source; without an override, this clears
its messages. `Unbind(renderer)` removes the registration and detaches without
clearing; a renderer being disposed clears its own state.

Sources publish batches with `Append(source, messages)` or
`Prepend(source, messages)`. Publishing does not store history; the source owns
its history and supplies the latest snapshot when a view binds.

`BindChat(renderer, chatFrame)` uses the Blizzard chat adapter. The router hooks
each chat frame's `AddMessage` and history buffer's `PushBack` once, regardless
of the number of subscribers. It reads up to 128 messages when a view binds.
Blizzard still owns chat filtering and native history. Combat Log is excluded.

Disabling an extra window unbinds it; enabling it reads the current history.
Disposing a renderer removes its subscription. Native hooks remain available
for other subscribers and reused chat frames; a new binding also checks whether
the frame's history buffer has changed.

## Demo override

`SetOverride(source)` temporarily connects all registered renderers to one
source. The router remembers their requested sources separately. Creating a
window or changing its real source during an override updates that registration
without interrupting the preview. `SetOverride(nil)` reconnects each registered
renderer to its latest requested source and reads fresh history.

Enabled extras with unavailable sources remain registered, so they can show a
preview. Disabled and disposed extras are unregistered and do not participate.
The host uses `HasSource(renderer)` to decide whether an extra window has content
to display, regardless of whether it comes from real chat or the demo.

The Demo module owns sample history and its timer. It publishes only through the
router and does not write to native chat frames or send chat messages. Its state
is not saved; profile changes stop it, and reloading starts with real chat.

## Verification

Run `luajit tests/message-router.lua` for subscription and source-switching
checks. This test does not simulate WoW frames, hooks, or rendering. Use the
message-delivery checks in [manual-testing.md](manual-testing.md) in WoW.
