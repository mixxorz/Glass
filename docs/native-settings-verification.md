# Native settings panel: in-game verification

1. Reload the UI and open **Settings → AddOns → Glass**. The existing settings
   tree should appear inside the native panel, without a separate Glass window.
2. Close Settings and run `/glass`. It should open the same native category on
   Home. Repeat while another native settings category is selected.
3. Navigate through Windows, Edit box, Chat options, Message formatting, and
   Profiles. Change a slider, font, toggle, and color, then reopen the panel and
   reload to check persistence.
4. Add an extra window. Its settings page should become selected in the native
   panel. Delete it and check that Main becomes selected without errors.
5. Switch profiles and join or leave a chat channel while the panel is open.
   Dynamic pages should refresh without opening a standalone options window.
6. From Home or Windows, use Unlock. Settings should close without reopening the
   game menu, and Glass's movers should be usable. Lock them and reopen Settings.
   `/glass lock`, `/glass unlock`, and `/glass demo` should still work.
7. With unapplied native settings, navigate to Glass using `/glass`. Pending
   native changes must remain pending. Unlock must respect the native close
   confirmation rather than bypassing it; apply or discard those changes before
   trying Unlock again if confirmation keeps the panel open.
8. Try `/glass` during combat. Opening should be rejected with the native combat
   error, without a blocked-action or Lua error. Try again after combat ends.
9. Check What's New and the color picker. Both must appear above Settings.
   Cancelling a grouped color edit must preserve its original per-type values.
10. Close with Escape, reopen from the AddOns list, and use `/glass` repeatedly.
    Glass should remain registered only once, with no stale or duplicate panels.
