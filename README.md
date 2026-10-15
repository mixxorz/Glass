![Glass](https://user-images.githubusercontent.com/3102758/90884068-9549a600-e3e1-11ea-944f-481bd894560e.png)

#### An immersive and minimalistic chat UI for World of Warcraft

_Now with support for Retail (Midnight), WoW Forever, Classic Era/Hardcore,
Burning Crusade Anniversary, and Mists of Pandaria Classic._

## Demo

https://github.com/user-attachments/assets/7f218129-6529-436d-aee4-ccfb3227a0ec

## Why?

I wanted to have a chat UI that didn't look like it was designed in 2004.

I tried several addons that customize the chat interface but was left
unsatisfied. So I decided to make one myself.

The goal of Glass is to be unobtrusive. Messages only appear when they come in
and fades out after a few seconds. Chat tabs are hidden until the player hovers
over the chat UI. There is no always-visible background. Glass is invisible
until the player needs it.

## Install

Glass is available on [CurseForge](https://www.curseforge.com/wow/addons/glass)

You may also download the latest release on [GitHub](https://github.com/mixxorz/Glass/releases)

## Commands

- `/glass` - open the Home page
- `/glass lock` - unlock all Glass windows for moving and resizing
- `/glass demo` - turn demo mode on or off

By default scrolling scrolls _per message_. If you have a really long message
and you want to scroll within it, use Shift+Scroll.

## Features

- Adds smooth animations to incoming chat messages.
- Lets you add extra Glass panes that track other chat tabs.
- Allows you to customize fonts, spacing, backgrounds, and layout.
- Offers profile-wide message formatting: channel aliases, independent colors,
  and optional Glass timestamps.
- Works alongside addons like Prat, ElvUI, and Leatrix Plus.

## Message formatting

Open `/glass` and select **Message formatting**. Settings are organized by
message type, with channel pages directly under Message formatting, and apply across all Glass
windows in the active profile, including extra windows.

- Channel aliases are enabled by default and editable. Disable an alias or leave
  it blank to preserve the original header; reset a rule to restore its defaults.
- Numbered channels default to the number captured with each message. Rules
  follow stable built-in channel identities or normalized custom-channel names,
  not numbered slots, so changing channel numbers does not move your settings.
- Default body RGB, channel-header RGB, and background RGBA are independent.
  Inline player/item colors remain distinct; zero background alpha is transparent.
- Glass timestamps are optional and off by default. Choose shared local-time
  presets (12- or 24-hour, with or without seconds) and a timestamp color.

Glass owns its timestamps. It hides recognizable native timestamp prefixes only
in its own display, without changing WoW's timestamp preferences. Original
messages are preserved. When original time or channel identity is missing,
Glass falls back conservatively: unknown historical times are not replaced with
the current time, and uncertain headers are left unchanged. Custom or legacy
history may retain its original styling. Restricted text can remain displayable
while timestamp and header transformations are unavailable.

Use `/glass demo` to preview formatting. Your chat input still sends real
messages while demo mode is active; turn it off to return to real chat.

## Addon compatibility

### ElvUI

Glass works with ElvUI, but make sure to disable the Chat module.

### Prat 3.0

Glass works with Prat, but make sure to disable the EditBox module.

There is no Prat timestamp-provider integration. Prat history can still flow
through native chat buffers; Glass uses saved original epoch times and identity
metadata where available. Missing metadata and uncertain provenance limit
historical timestamp and channel formatting, and custom or legacy histories
may retain their original styles.

Arbitrary timestamps already baked into Prat's saved text may remain and can
coexist with a Glass timestamp. Disable Prat timestamp generation for future
messages when using Glass-owned timestamps. This does not erase prefixes
already saved in history.

### Leatrix Plus

Glass works with Leatrix Plus. You might encounter issues when enabling features
that modify chat behaviour such as "Recent chat window" or "Use easy resizing".
Switching these features off will resolve issues with Glass.

## Issues and suggestions

Check the [Issue tracker](https://github.com/mixxorz/Glass/issues) on GitHub
to see if someone else has already reported your issue. If not, leave a comment
on [CurseForge](https://www.curseforge.com/wow/addons/glass).

## License

MIT License

Copyright (c) 2020 Mitchel Cabuloy
