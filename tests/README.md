# Fantasy mechanic regression tests

These are opt-in integration tests for a developer's own Brotato 1.1.15.4 installation, Mod Loader 6.3.0, Fantasy and its declared dependencies. No game files or saves are included. The test mod instantiates the real extended Player and Erosion scripts and exercises the normal PlayerRunData serialization methods.

Use a separate test copy/configuration of the game, never your normal save profile. In that test configuration set:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="Fantasy-Mechanics-Test"
```

Install the mod under `mods-unpacked/Local-FantasyRegression/` (copy the corresponding directory from here), or ZIP that directory with the same `mods-unpacked/` prefix and place it in your test Mod Loader directory. Launch the test game with `--fantasy-regression`. The tests refuse to run unless both that flag and the `Fantasy-Mechanics-Test` user-directory marker are present. They reset in-memory run state and quit the process when done. They are not enabled during a normal launch.

Read `CC_RESULT` in the game log: failures must be empty, the exit code must be zero, and there must be no `SCRIPT ERROR` entries. A missing result is a failure, not a pass.

Coverage:

- Same-player Erosion stacking remains intact.
- Two co-op players using the same Erosion source retain separate ownership, damage and critical parameters.
- Cardinal's partial 12-soul progress survives Player replacement between waves.
- Partial progress survives a real JSON serialization/deserialization round-trip and PlayerRunData duplication.
- Old saves without the new counter field remain loadable and earn rewards normally.
- Multiple effects responding to the same consumable count each pickup once and award both bonuses at the correct threshold.
- Co-op pickup progress is independent for each player.

These focused tests do not establish complete coverage of the expansion, rendering, multiplayer networking or every third-party mod combination.

Additional item regressions cover normal/cursed Prism Tower, Silver Pocket Watch and Nuclear Drum descriptions through JSON save/load, fractional Erosion chance, integer watch trigger counts, and migration of old Prism effect IDs without changing the input dictionary. The two-stage local audit tested 299 installed items in normal/cursed variants (598 cases); the broad harness and proprietary compatibility overlay are not included here. Base-game ProjectileEffect, DoubleValueEffect and Lootworm workarounds remain outside this PR.
