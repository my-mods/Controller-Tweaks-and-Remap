# Dawnwalker Controller Tweaks v1.1.0

- Swap LB with LT and RB with RT in the default controller layout.
- Tap View/Back for Map; hold for 0.30 seconds for Game Hub.
- Press Start/Options to reveal the compass temporarily, using HUDTweaks' idle/fade settings.
- Stable mod name and Vortex-ready mixed Lua/IoStore package.

## Installation

Import `Dawnwalker-Controller-Tweaks-1.1.0.zip` into Vortex, replacing earlier
Controller Swap / Controller Tweaks packages and the old menu-shortcut mods.
Requires HUDTweaks v2 and UE4SS. This mod must win HUDTweaks' `main.lua` conflict;
the separate prompt fix should win `HUDTweaks.ini`. Use the Root mod type.
Do not install the automatic source-code archives.

## Compatibility and testing

Built for Steam build 25129649 / executable CL-257186. Lua 5.4 tests, IoStore verification,
controller asset round-trip comparison, and Vortex installer planning checks pass.
Native input and visuals have not been validated in-game; this is an initial testing release.
Start's normal menu/legend action is retained and can obscure the compass reveal.
