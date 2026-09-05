CONTROLLER SHOULDER-TRIGGER SWAP + map shortcut COMPATIBILITY 1.0.0
================================================================

Game: The Blood of Dawnwalker (PC)
Built for Steam build 25129649 / executable CL-257186.
Current official public patch at build time: Hotfix 1.0.2.

CONTROLS
--------
The default controller preset is changed globally:
- LB actions move to LT.
- LT actions move to LB.
- RB actions move to RT.
- RT actions move to RB.

This includes the following current mappings:
- Block: LB -> LT
- Focus Mode and Combat Abilities: LT -> LB
- Attack and Overworld Abilities: RB -> RT
- Shadowstep: RT -> RB
- Photo Mode rise/fall also follow the same global physical-button swap.

map and hub shortcuts compatibility is built in:
- Tap Xbox Back/View: open the map.
- Hold Xbox Back/View for 0.30 seconds: open Game Hub.
- DualSense uses the touchpad for the game's Gamepad_Special_Left input.

SCOPE
-----
- Controller only.
- Default controller layout only.
- Keyboard bindings are unchanged.
- Replaces IA_Hub_Launch, IA_Hub_Map, and RIP_GamepadDefault.

VORTEX INSTALLATION
-------------------
1. Close the game.
2. Disable the original Dawnwalker menu-shortcut mod and the earlier
   menu-shortcut compatibility mod. This package supersedes both.
3. Install this ZIP through Vortex, enable it, and deploy.
4. If Vortex reports a conflict with another default-controller mapping mod,
   this combined patch must win to keep both the swap and map shortcut behavior.

UNINSTALLATION
--------------
Disable/remove this mod in Vortex and deploy again. Re-enable the previous map shortcut
compatibility mod only if you still want map shortcut without the shoulder-trigger swap.

COMPASS TOGGLE FINDING
----------------------
The current default layout has no unused standard controller button. Every stick,
D-pad direction, face button, shoulder, trigger, View/Back and Menu/Start input is
already mapped. UE4SS RegisterKeyBind accepts Windows keyboard/mouse virtual keys,
not Unreal gamepad FKeys, so HUDTweaks cannot directly assign its toggle that way.
A separate hold/chord runtime mod or repurposing an existing action would be required.

VALIDATION
----------
The IoStore container was built as UE5.5 content and round-trip checked. It contains
only IA_Hub_Launch, IA_Hub_Map and RIP_GamepadDefault. The decoded preset has 31
mappings and confirms LB <-> LT and RB <-> RT across every affected action.
