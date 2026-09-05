# Dawnwalker Controller Tweaks v1.3.0

Removed the Start/Options compass reveal feature after the user reported it did
not work and that heightened senses already displays quest objectives. No Lua
scripts or HUDTweaks overrides are shipped. HUDTweaks, UE4SS and other mods are
not required by Controller Tweaks.

Retains the bidirectional LB/LT and RB/RT swap, map and hub shortcuts, and wider walking
range (processed MoveFast threshold 0.70 -> 0.90). Controller asset payloads are
unchanged from v1.2.1. The name, internal ID, container paths and ZIP name stay stable.

## Vortex replacement

1. Close the game. Disable the previous Controller Tweaks entry in Vortex and deploy
   so Vortex removes its old HUDTweaks script overrides.
2. Import Dawnwalker-Controller-Tweaks.zip and replace/reinstall that same mod entry
   from the new archive. Use replacement, not a merge that retains old files.
3. Select Root (game folder), enable the replacement, and deploy through Vortex.
   Redeploying the old entry alone does not process the new archive.
4. Keep one Controller Tweaks entry. Earlier standalone menu-shortcut,
   menu-shortcut and Controller Swap variants remain superseded.

The new package has no HUDTweaks main.lua conflict. If you keep HUDTweaks for its
own features, its original Scripts/main.lua should become active again; Vortex
should remove ControllerCompass.lua from the old package. If you use Prompt
Dismissal Fix, it remains independent and still wins HUDTweaks.ini. Do not remove
HUDTweaks or UE4SS if other mods still need them. Manage all cleanup through Vortex.

Another cooked mod replacing IA_Move, IA_Hub_Launch, IA_Hub_Map or
RIP_GamepadDefault needs an asset compatibility patch. Disable/remove Controller
Tweaks and deploy through Vortex to uninstall.

## Validation

Source capture remains Steam build 25129649 / executable CL-257186. Prerelease:
in-game walking feel remains unverified. After Vortex replacement, check slow stick
sweeps, straight/diagonal full-tilt running, sprint, crouch, combat, keyboard input,
shoulder/trigger controls and map and hub shortcuts. If HUDTweaks remains installed,
verify its own HUD behavior after its original main.lua is restored by Vortex.
