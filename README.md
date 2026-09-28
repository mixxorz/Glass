# Abandoned

Please use [LS: Glass](https://www.curseforge.com/wow/addons/ls-glass "LS: Glass")

This project is the original Glass addon by me. I no longer play the game so this project has been abandoned.

i_lightspark has been kind enough to keep the spirit of Glass alive by releasing their own version. Please use that instead.

* [LS: Glass on CurseForge](https://www.curseforge.com/wow/addons/ls-glass)
* [LS: Glass on Wago](https://addons.wago.io/addons/ls-glass)

**Original description follows**

---

![Glass](https://user-images.githubusercontent.com/3102758/90884068-9549a600-e3e1-11ea-944f-481bd894560e.png)

#### An immersive and minimalistic chat UI for World of Warcraft

[![Demo](https://thumbs.gfycat.com/SkinnyPopularIsabellineshrike-size_restricted.gif)](https://gfycat.com/skinnypopularisabellineshrike)

(Click for slightly higher resolution)

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

* `/glass` - open the Home page
* `/glass lock` - unlock all Glass windows for moving and resizing
* `/glass demo` - turn demo mode on or off

Home keeps the compact **Info** layout with version information, **What’s New**,
command hints, and **Unlock**. Window settings and **Add window** remain under
**Windows** in the sidebar.

## Demo mode

Turn on **Demo mode** on Home, or run `/glass demo`, to preview your settings
with sample chat. Main and every enabled extra window show the same mix of
party, guild, whisper, loot, and system messages, all marked **[Demo]**. There
is enough history to scroll, and another message arrives every few seconds.
Each window keeps its own styles, animations, and interaction settings.

Demo messages stay inside Glass; they are never sent or added to Blizzard's
chat history. Your chat input still sends real messages. Turn demo mode off to
return to current real history, including messages received during the demo.
Reloading or switching, copying, or resetting a profile also ends the demo.
Combat Log and disabled extra windows are left alone.

## Extra windows

Glass still replaces the main chat interface. You can also create display-only
windows that mirror individual chat tabs, including tabs filtered to loot,
guild chat, or other message types. Combat Log cannot be mirrored.

Create one through **`/glass` → Windows → Add window**, or right-click a chat tab
and choose **Create Glass window**. Each extra window has independent message
and tab-bar styling, fade timings, position, size, and scrollback. Its optional
tab bar displays only its source tab. Typing still uses the main Glass input.

Under a window's **Behavior** settings, disable hover, scrolling, or clickable
links separately, or enable **Non-interactive** to pass mouse input through to
the game. `/glass lock` still lets you position non-interactive, disabled, or
unbound windows. Click **Lock** to finish editing.

Disabling a window keeps its settings. Deleting it does not delete its source
tab. If the source tab is closed, choose a replacement in the window's settings.
Window styles and layouts belong to the Glass profile; source assignments are
saved separately for each character. Automatically opened conversation tabs
need to be selected again after logging in.

Settings are organized by window, with tabs for **Window**, **Messages**,
**Tab bar**, and **Behavior**. Main also has **Chat input**, before Behavior,
with its own horizontal padding. Tab-bar and message gradient widths are
independent. The main tab bar also supports configurable spacing between tabs.

Use **Top edge fade** and **Bottom edge fade** under **Messages → Layout** to
soften the edges of the message pane. Both start at 14 pixels. Set either to 0
to turn off that fade. The bottom fade appears when you scroll up and goes away
when you return to the latest message. These options are only available if your
WoW client supports frame alpha gradients.

## Customization

Not everyone likes the same look. Glass tries to accommodate your own
preferences by giving you options to change the:

* Chat frame width, height, and location
* Font and font size
* Message fade out delay
* Background opacity

Sliders use practical drag ranges. Existing values outside those ranges are
preserved; use the numeric entry to enter values within the wider supported limits.

Moreover, unlike the default chat UI, these settings may be shared between
characters.

## Addon compatibility

### ElvUI

Glass works with ElvUI, but make sure to disable the Chat module.

### Prat 3.0

Glass works with Prat, but make sure to disable the EditBox module.

Prat Timestamps work with Glass but with a caveat. Prat allows you to select
which tabs to enable timestamps on. This is currently not supported and
Timestamps will be enabled on all tabs if the Prat Timestamps module is loaded.
If you want to disable Prat Timestamps, you'll need to set the module to "Don't
load" (just "Disabled" won't work).

Note: WoW's built-in timestamps work with Glass. (Interface -> Social ->
Timestamps)

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
