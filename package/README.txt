DAWNWALKER CONTROLLER TWEAKS 1.2.0

Wider walking range: the MoveFast input threshold is raised from 0.70 to 0.90.
Push the left stick further before running; full-tilt input remains unchanged.
Replace/reinstall the existing Vortex entry from this ZIP and deploy.
================================================================

Game: The Blood of Dawnwalker (PC)
Built for Steam build 25129649 / executable CL-257186.
Requires HUDTweaks v2 and a working Dawnwalker-compatible UE4SS installation.

This is the stable name of the former Controller Swap + map shortcut + Start Compass
Reveal mod, not a separate mod. Version 1.1.1 fixes controller discovery after loading.
Replace the previous package in Vortex; do not enable both. Future releases keep
the name and change the version. Internal IDs and deployed paths are unchanged.
The archive is always Dawnwalker-Controller-Tweaks.zip and is overwritten on builds.
Keep one Vortex mod entry and use its replace/update flow for this archive.

CONTROLS
--------
Walking uses more stick travel before the fast-movement tag activates. The 0.90
threshold is measured on processed movement input, so Steam Input and the game's
deadzone/sensitivity settings can affect the physical stick position. No input
delay is added. Direction, maximum input, camera, sprint bindings, and keyboard
movement mappings are preserved. This changes the existing IA_Move asset; it
does not replace any user INI. In-game feel and diagonal running need testing.

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

Press Start (Xbox Menu) / PlayStation Options:
- A normal click reveals the compass immediately; no long press is needed.
- It uses HUDTweaks' idleAfterSeconds, fadeOutSeconds and idleOpacity settings.
  With your captured settings: 2 seconds visible, then a 0.8-second fade to zero.
- Another click refreshes the timer. Holding the button does not repeat.
- This never toggles hidden state or permanently pins the compass.
- The compass strip, cardinal headings and pins change together.
- Otherwise the compass follows your normal HUDTweaks behavior, including combat.
- F8 suspension of HUDTweaks suspends this feature too.

Start's original controls-legend/menu action still executes: this binding observes
the button, it does not consume it. A press may therefore also open the normal
Start menu or change the legend. This limitation still needs an in-game check.

SCOPE
-----
- Controller only.
- Default controller layout only.
- Keyboard bindings are unchanged.
- Replaces IA_Hub_Launch, IA_Hub_Map, and RIP_GamepadDefault.
- Overlays HUDTweaks/Scripts/main.lua and adds ControllerCompass.lua. Your
  HUDTweaks.ini and the separate Prompt Dismissal Fix remain independent.

VORTEX INSTALLATION
-------------------
1. Close the game.
2. Disable the original Dawnwalker menu-shortcut mod and the earlier
   menu-shortcut compatibility mod, plus Controller Swap v1.0.0.
   This package supersedes all three.
3. Install this ZIP through Vortex, enable it, and deploy.
4. If Vortex reports a conflict with another default-controller mapping mod,
   this combined patch must win to keep both the swap and map shortcut behavior.
5. Keep HUDTweaks enabled. Make this mod win the HUDTweaks main.lua file conflict.
   Keep your Prompt Dismissal Fix enabled and winning the INI conflict.
6. The Vortex type should be Root (game folder); the archive's Dawnwalker paths
   route both the controller containers and Lua files to their correct locations.

UNINSTALLATION
--------------
Disable/remove this mod in Vortex and deploy again. Re-enable the previous map shortcut
compatibility mod only if you still want map shortcut without the shoulder-trigger swap.

COMPASS DIAGNOSTICS
-------------------
After loading a save, UE4SS.log should contain:
  [ControllerCompass] Input ready: press Start/Options to reveal compass.
Each press logs Compass revealed; idle fade will resume. API failures are logged
instead of being interpreted as button presses. A held button across loading or
a long frame stall must be released before the feature rearms.
Version 1.1.5 uses one persistent game-thread timer and a validated gameplay-pawn
lookup. It checks local controller possession and retries after malformed lookup
results or input errors. The startup log reports Loaded v1.1.5; game-thread timer active.
Requires UE4SS with LoopInGameThreadWithDelay (present in diagnosed build 97b7e501).
If it logs Scheduler unavailable, that UE4SS build lacks the required API.
The new build needs an in-game retest, including after loading another save.

VALIDATION
----------
The IoStore container was built as UE5.5 content and round-trip checked. It contains
only IA_Hub_Launch, IA_Hub_Map and RIP_GamepadDefault. The decoded preset has 31
mappings and confirms LB <-> LT and RB <-> RT across every affected action.
Lua tests cover click reveal, timer refresh, idle fade, held buttons, frame stalls,
controller changes, input errors and compass-only opacity. The new binding still requires
an in-game check on this UE4SS build; offline tests cannot verify native input.

VORTEX METADATA UPDATE 1.1.4
The ZIP now generates vortex_override_instructions.json from mod.manifest, so Vortex sets the display name, version, and description during installation. Runtime payloads and file destinations are unchanged.

Replace/reinstall the updated ZIP through Vortex using the existing mod entry, then deploy. Redeployment alone cannot read new archive metadata. This does not provide automatic update discovery or merge duplicate Vortex entries.

Archive filename: Dawnwalker-Controller-Tweaks.zip
