DAWNWALKER CONTROLLER TWEAKS 1.3.0

ALL INCLUDED CHANGES
- LB <-> LT (PlayStation L1 <-> L2) and RB <-> RT (R1 <-> R2), in both directions.
- Wider left-stick walking range: the existing walk-to-run threshold changes from 0.70 to 0.90.
- Tap Back/View (PlayStation touchpad) for Map; hold 0.30 seconds for Game Hub.

The Start/Options compass feature has been removed. Controller Tweaks no longer
requires HUDTweaks, UE4SS, Prompt Dismissal Fix, or any other mod.

Game: The Blood of Dawnwalker (PC), default controller layout.
Source capture: Steam build 25129649 / executable CL-257186.
Compatibility with later game versions is not established.

CONTROLS AND SCOPE
Walking uses more processed input before fast movement activates. Game/Steam Input
deadzone and sensitivity settings affect the physical stick position. Full-tilt
input, direction, sprint bindings, camera and keyboard mappings are preserved.
IA_Move is shared with keyboard input. No input delay or replacement INI is added.

The shoulder/trigger swap applies globally to the default controller preset:
- Block: LB -> LT
- Focus Mode and Combat Abilities: LT -> LB
- Attack and Overworld Abilities: RB -> RT
- Shadowstep: RT -> RB
- Photo Mode rise/fall follows the same physical-button swap.

Only IA_Move, IA_Hub_Launch, IA_Hub_Map and RIP_GamepadDefault are replaced.
Start/Options has no custom compass behavior in this version.

VORTEX INSTALLATION AND UPDATE FROM 1.2.1 OR EARLIER
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

For a first installation, import this ZIP as Root (game folder), enable and deploy.
If another mod supplies identically named containers, Controller Tweaks must win
those three files to retain its changes. Differently named cooked containers can
replace the same assets without a Vortex file conflict; an asset compatibility
patch is needed. Vortex file rules cannot merge assets.

UNINSTALLATION
Disable/remove Controller Tweaks and deploy through Vortex. Re-enable an earlier
map shortcut mod only if you want its behavior without Controller Tweaks.

STABLE IDENTITY
The name, internal mod ID, container paths and Dawnwalker-Controller-Tweaks.zip
filename remain stable. Versions stay in metadata
and GitHub tags. Use Vortex's replace/update flow; the filename does not merge
duplicates automatically. No user settings INI is replaced.

VALIDATION
The actual ZIP must contain exactly seven allowlisted files, including one
container triple and no Lua scripts. Offline checks verify the container, extract
its four assets, validate the movement threshold and unchanged remaining payloads,
and test installed Vortex installer/metadata planning with mocked state.
Native movement feel still needs testing, so this remains a prerelease.
