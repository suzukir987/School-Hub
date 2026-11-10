# Shared startup requirements

Every game uses this launcher and the shared Auth, Loading and Hub. Do not copy an older bootstrap into a new game adapter.

Common literals are resolved at build time and emitted in native prototypes of at most 128 strings. The large runtime Base85 decoder is retired. Preserve the exact returned common factory, signed byte verification, embedded-common identity matching, bounded retry and cancellation.

Preserve the native compile/evaluation boundary, nil-safe returns, copied caller options and at most 16 startup scheduler handoffs. The short loader downloads an approved immutable bootstrap commit and schedules it once with `task.defer`.

Before publication, run the source/protected adapter regressions and the actual composed signed bootstrap tests. Record exact source, common, API, bootstrap and loader hashes. Unchanged components can inherit a hash-bound proof. Update `startup-profile.json` from those proofs and run `node tools/check-launcher.cjs`. A summary or text match does not replace the runtime tests.

Publish the bootstrap commit first, verify its exact bytes, then update the loader's immutable pointer in a second commit and independently verify the canonical loader URL. Keep the new bootstrap and the loader's currently approved target separate during this transition. Never replace the pointer with `main/bootstrap.lua`.

Disabled, paused and stopped features must not inspect executor callbacks/constants, install hooks, mutate game methods or send feature remotes. Cleanup restores only still-owned hooks and cancels owned tasks/connections. New adapters preserve the accepted shared design and game-specific settings.

Native Roblox/device/executor checks follow publication. Local tests and one successful user launch do not certify all games or future executor versions. Retired diagnostic commands are no longer maintained in the default branch; historical revisions remain in Git.
