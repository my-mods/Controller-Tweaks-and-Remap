# Dawnwalker Controller Tweaks v1.2.1

Documentation update: both READMEs now begin with the complete feature list: LB/LT and RB/RT swaps, the 0.70-to-0.90 walk-to-run threshold, map and hub shortcuts, compass reveal/fade, and compass loading recovery. All five gameplay files are byte-identical to v1.2.0.

Walking has more left-stick travel before the game requests fast movement.
The existing IA_Move MoveFast threshold changes from 0.70 to 0.90. Full-tilt
input, movement direction, sprint bindings, camera and keyboard mappings remain
unchanged. The threshold uses processed movement input; game/Steam Input
deadzone and sensitivity settings affect its physical position.

Includes the v1.1.5 compass loading/polling fix, shoulder/trigger swap, and
map and hub shortcuts. No new movement Lua hooks or replacement user settings INI.

## Vortex update

Import **Dawnwalker-Controller-Tweaks.zip** and replace/reinstall the existing
Controller Tweaks entry. Use **Root (game folder)**, then deploy through Vortex.
Keep HUDTweaks v2 and compatible UE4SS enabled; Controller Tweaks wins
`HUDTweaks/Scripts/main.lua`. If used, Prompt Dismissal Fix remains enabled and
wins `HUDTweaks/Scripts/HUDTweaks.ini`. Disable the earlier standalone menu-shortcut
and controller compatibility variants. Keep one Controller Tweaks entry.

An asset mod replacing IA_Move needs a compatibility patch. Differently named
containers may conflict without Vortex reporting a file collision.
Disable Controller Tweaks and deploy in Vortex to uninstall.

## Validation and remaining check

Built from installed Steam build 25129649 / executable CL-257186 stock assets.
The actual ZIP container verifies and extracts successfully. Its four assets
round-trip correctly; the only IA_Move payload change is the 0.70-to-0.90 float.
Unknown upstream snapshots are rejected. Lua regression/compilation checks and
Vortex installer planning use offline mocked state, with no live deployment.

Published as a prerelease until tested in game. With the replacement deployed,
check slow stick sweeps, full-tilt running in straight and diagonal directions,
sprint, crouching, combat movement, keyboard movement, and Start/Options compass
reveal before and after reloading a save. No live in-game result is claimed.
