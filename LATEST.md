# 2.0.0-alpha5 (2026-10-14)

Changes

- Mouse wheel now scrolls per message; use Shift+Scroll to move within long messages.
- Secret messages retain Glass's styling and fades; incoming batches containing secret text skip sliding.
- Secret text skips Glass's icon-offset adjustment and Glass-added Prat timestamps.

Bug fixes

- Fix Lua errors caused by secret chat text during boss encounters and other restricted content (#166).
- Preserve ordinary-message slide animations when secret messages remain in history.
