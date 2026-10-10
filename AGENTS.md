# Repository instructions

## Testing

Automated tests are not allowed in this repository. They require mocking the
WoW client and provide little value compared with verifying behavior in-game.
Do not add test files or test harnesses.

Use Lua syntax checks, luacheck, code review, and manual in-game verification
instead. Static checks do not replace in-game verification.

## Installing for in-game testing

When the user asks to install a branch or worktree as the Glass addon, point the
existing WoW `Interface/AddOns/Glass` symlink at that checkout. Use a symlink
rather than copying files so code changes are available after a UI reload.
Ensure the checkout's addon libraries are available, and verify the link target.

The current installation is
`/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/Glass`.
Do not change other client installations unless requested. If the addon path is
a real directory rather than a symlink, ask before replacing it.
