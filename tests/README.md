# Regression checks

Run from the repository root with Lua 5.1 or LuaJIT:

```sh
luajit tests/editbox_spec.lua
```

The check needs the packaged libraries at `libs/LibStub/LibStub.lua` and
`libs/AceHook-3.0/AceHook-3.0.lua`. These are untracked dependencies listed in
`.pkgmeta`; use copies from an existing Glass installation or packaging checkout.

The check uses the real AceHook library with simulated WoW frames. It covers
Prat-style arrow-key hooks before and after Glass initialization, library
re-embedding, focus callbacks, text insets, and the edit-box hide animation.
Actual addon startup and interactions still need verification in WoW.
