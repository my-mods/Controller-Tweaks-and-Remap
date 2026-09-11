# Controller Tweaks and Remap

![Controller Tweaks and Remap](Nexus/thumbnail.jpg)

Controller improvements for *The Blood of Dawnwalker* on PC, with one personal INI for all 31 bindings in the Default and Alternative controller presets.

## Experimental input fixes

This branch provides **Controller-Tweaks-and-Remap.zip**, a complete alternative package based on 1.5.2.

- Controller overrides update every linked action in the active input profile, including Focus actions whose context contains an unresolved key. Keyboard bindings retain their separate profile slot.
- Focus controls take priority over ordinary interaction while Focus is active. This addresses shared Interact/Attack buttons such as X in Alternative without moving Interact globally.
- Attack and the controller ability wheel can use different buttons. Both follow their own INI setting.

See [Input bindings](INPUT-BINDINGS.md) for linked actions, input rules and configuration examples.

- **Configurable controls:** assign a physical controller button to each action in `ControllerTweaks.ini`. Changes load at game startup.
- **Linked Bite controls:** `Player_Drink_Blood` starts Voracious Bite in Focus and controls the hold while feeding. Necrospeak in Focus shares this button.
- **Alternative preset support:** retains the original Alternative layout, with Bite/feeding on LB/L1 instead of X/Square to avoid the Attack conflict.
- **Shoulder/trigger swap in the Default preset:** LB ↔ LT and RB ↔ RT (PlayStation L1 ↔ L2 and R1 ↔ R2), including Photo Mode.
- **Easier walking:** gives you a wider stick range for walking. Shapeshift and Mercurial Fervour stay active when you steer with the stick fully pushed.
- **Short press / long press:** by default, Back/View (PlayStation touchpad) opens the Map on a short press and the Game Hub on a long press (0.30 seconds).

With the Default layout, Block is LT, Focus Mode/Combat Abilities LB, Attack/Overworld Abilities RT, and Shadowstep RB. Alternative retains its face-button attack/block layout and uses LT/L2 for Focus; walking and Map/Game Hub improvements work with either preset.

## Requirements and installation

Requires **Dawnwalker UE4SS RC5 for build 25129649**, including its reflected struct ref/out support, TMap API and `ExecuteInGameThreadWithDelay`. Its reference base is **3.0.1 Beta, commit 97b7e501c**. The older UE4SS 3.0.0 stable release does not provide all required APIs. Install the appropriate loader through Vortex separately; it is not bundled. HUDTweaks is not required.

1. Download **Controller-Tweaks-and-Remap.zip**. Use this complete experimental package in place of the main package; do not enable both copies in Vortex.
2. Import it into Vortex 1.14 or newer as **Root (game folder)**, then enable and deploy.
3. Select **Default** or **Alternative** in the game's controller settings, then restart the game.

To update, use Vortex's replace/reinstall flow on the existing entry with the new ZIP and deploy. Keep one enabled Controller Tweaks and Remap entry. Legacy personal settings under your Windows profile are imported once. Back up the generated settings.ini before uninstalling/reinstalling; see SETTINGS.md for migration and restoration.

To uninstall, close the game, disable/remove the mod and deploy through Vortex. Restart to discard runtime changes. Back up settings.ini before removal and restore it before the next launch if reinstalling.

## Settings

Use [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) from the main menu. Press Apply, then fully restart the game. See [SETTINGS.md](SETTINGS.md) for all controls, first-use import and preference backups. Console settings commands are retired.

## Compatibility

Other mods that change walking or controller controls may conflict.

Earlier standalone shoulder/trigger and TapMapHoldMenu/controller compatibility mods are superseded; disable them through Vortex. This mod has its own UE4SS directory and no HUDTweaks overrides. All three `zzz_DawnwalkerControllerTweaks_P` container files must come from the same release.

Based on Steam build **25129649 / CL-257186**. The game's cached button prompts or controller-layout screen may show the original preset even when a runtime binding changes. Actual actions follow your chosen bindings.

Original mod work is licensed under [MIT](LICENSE.txt). Game assets belong to their respective rightsholders and are not relicensed.

# Settings

Install [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. Start the game once, then open Main Menu > Mod Settings > All Mods. Select this mod, change settings and press Apply. **Fully close and restart the game after Apply.** Restore discards unapplied changes; Reset selects this mod’s defaults.

The stable menu ID is `oOCamilleOo_ControllerTweaksAndRemap`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Runtime remapping | Off, On |
| Diagnostics | Debug logging | Off, On |
| Bindings | Camera Look | Inherit preset, Left stick axes, Right stick axes |
| Bindings | Combat Abilities | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Attack | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Block | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Dodge | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Draw Weapon | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Switch Weapon | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Target Lock | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Target Next | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Combat Target Previous | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Photo Exit | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Photo Vertical Fall | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Photo Vertical Rise | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Abilities Gamepad | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Drink Blood | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Focus Mode | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Hub Launch | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Hub Map | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Interact | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Quickslot Bottom | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Quickslot Left | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Quickslot Right | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Quickslot Top | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Player Shadowstep | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Toggle Controls Legend | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Toggle Quickslot | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Traversal Crouch | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Traversal Jump | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Traversal Movement Axis | Inherit preset, Left stick axes, Right stick axes |
| Bindings | Traversal Planeshift | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |
| Bindings | Traversal Sprint | Inherit preset, A / Cross, B / Circle, X / Square, Y / Triangle, LB / L1, LT / L2, RB / R1, RT / R2, LS / L3, RS / R3, View / Touchpad, Menu / Options, D-pad Up, D-pad Down, D-pad Left, D-pad Right, Right stick Left, Right stick Right |

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.
