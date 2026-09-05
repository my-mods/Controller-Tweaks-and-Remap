# Dawnwalker Controller Tweaks v1.1.5

Fixes the compass input path that failed during loading with `table expected, got
function`. The gameplay-pawn lookup now validates engine results and current local
controller possession. A single persistent game-thread timer replaces repeated
async callback registration. Transient lookup/input errors cancel the reveal and
retry on later ticks; a held button must be released before another reveal.

The prior log also reported `Lua::Registry::get_function_ref: Ref was not function`.
Removing repeated callback registration addresses that risky scheduling path;
the exact native cause of the original malformed return has not been proven.

Requires HUDTweaks v2 and a Dawnwalker-compatible UE4SS build providing
`LoopInGameThreadWithDelay` (present in installed build 97b7e501). Built from the
existing Steam build 25129649 / CL-257186 asset snapshots. Compatibility with later
game or HUDTweaks versions is not established.

## Install/update

Close the game. Replace/reinstall **Dawnwalker-Controller-Tweaks.zip** through the
existing Vortex entry, choose **Root (game folder)**, enable and deploy.
Keep HUDTweaks enabled; Controller Tweaks must win `HUDTweaks/Scripts/main.lua`.
Keep Prompt Dismissal Fix winning `HUDTweaks/Scripts/HUDTweaks.ini` if used.
Disable older standalone menu-shortcut/controller compatibility variants in Vortex.
The stable ZIP name and Vortex display/version metadata are preserved.
Disable/remove this mod and deploy through Vortex to uninstall.

## Validation and remaining check

The new regression reproduces the logged iterator error with the legacy adapter.
The corrected, generated PlayerPawn adapter passes malformed-return recovery,
retained menu controller, possession changes, held-button suppression, scheduler
diagnostics and input-error recovery tests under Lua 5.4. Existing compass opacity,
fade, startup/loading and suspension tests pass. Upstream changes and missing,
duplicated or changed integration anchors are rejected before generating output.

Both consecutive builds replace the same ZIP. Container verification and round-trip
extraction preserve all three controller assets. The actual ZIP passes its allowlist,
payload-byte, manifest/metadata and installed Vortex installer-planning checks.

**Prerelease: native input and visuals still require an in-game test.** After loading
a save, look for `Loaded v1.1.5; game-thread timer active` and `Input ready` in
UE4SS.log. Let the compass fade, release Start, then press Start/Options: it should
reveal and resume idle fading. Repeat after loading another save. Holding Start
does not repeat; holding View/Back opens the hub. Start's original menu/legend
action is still observed and may obscure the compass. No live deployment is made
by this build or its tests.
