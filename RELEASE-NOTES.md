# Dawnwalker Controller Tweaks v1.1.1

Fixes a controller-cache bug consistent with the reported Start button failure:
a still-valid menu controller could remain cached after gameplay possession,
preventing input from ever becoming ready. The module now follows HUDTweaks'
detected gameplay pawn and revalidates its controller. Waiting states are logged.

- Swap LB with LT and RB with RT in the default controller layout.
- Tap View/Back for Map; hold for 0.30 seconds for Game Hub.
- Press Start/Options to reveal the compass temporarily, using HUDTweaks' idle/fade settings.
- Stable mod name and Vortex-ready mixed Lua/IoStore package.

## Installation

Import `Dawnwalker-Controller-Tweaks-1.1.1.zip` into Vortex, replacing earlier
Controller Swap / Controller Tweaks packages and the old menu-shortcut mods.
Requires HUDTweaks v2 and UE4SS. This mod must win HUDTweaks' `main.lua` conflict;
the separate prompt fix should win `HUDTweaks.ini`. Use the Root mod type.
Do not install the automatic source-code archives.

## Compatibility and testing

Built for Steam build 25129649 / executable CL-257186. Lua 5.4 tests, IoStore verification,
controller asset round-trip comparison, and Vortex installer planning checks pass.
The retained-menu-controller regression fails against v1.1.0 and passes with v1.1.1.
Native input and visuals need an in-game retest; this is a testing prerelease.
Start's normal menu/legend action is retained and can obscure the compass reveal.
