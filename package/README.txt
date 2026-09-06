# Dawnwalker Controller Tweaks

Controller improvements for *The Blood of Dawnwalker* on PC, with an INI for all 31 bindings in the default controller preset.

- **Configurable controls:** assign a physical controller button to each action in `ControllerTweaks.ini`. Changes load at game startup.
- **Shoulder/trigger swap by default:** LB ↔ LT and RB ↔ RT (PlayStation L1 ↔ L2 and R1 ↔ R2), including Photo Mode.
- **Easier walking:** raises the left-stick walk-to-run threshold from 0.70 to 0.90.
- **Short press / long press:** by default, Back/View (PlayStation touchpad) opens the Map on a short press and the Game Hub on a long press (0.30 seconds).

With the supplied layout, Block is LT, Focus Mode/Combat Abilities LB, Attack/Overworld Abilities RT, and Shadowstep RB.

## Requirements and installation

Requires **UE4SS compatible with Dawnwalker**, including its TMap API and `LoopInGameThreadWithDelay`. The reference build is **3.0.1 Beta, commit 97b7e501c**. The older UE4SS 3.0.0 stable release does not provide all required APIs. Install the appropriate loader through Vortex separately; it is not bundled. HUDTweaks is not required.

1. Download **Dawnwalker-Controller-Tweaks.zip** from [Releases](https://github.com/my-mods/Dawnwalker-Controller-Tweaks/releases).
2. Import it into Vortex 1.14 or newer as **Root (game folder)**, then enable and deploy.
3. Select the game's **default controller preset**.

To update, back up your edited INI, then use Vortex's replace/reinstall flow on the existing entry with the new ZIP and deploy. The ZIP includes a complete default INI; replacement does **not** merge your preferences. Restore your chosen values into the new file. Keep one enabled Controller Tweaks entry.

To uninstall, close the game, disable/remove the mod and deploy through Vortex. Restart the game to discard runtime changes.

## Configuration

Close the game. In Vortex, use **Open in File Manager** on this mod and open:

`Dawnwalker/Binaries/Win64/ue4ss/Mods/DawnwalkerControllerTweaks/Scripts/ControllerTweaks.ini`

Edit the physical button beside each action, save, deploy through Vortex and restart the game. For example, these overrides restore the stock combat shoulder/trigger arrangement:

```ini
[Bindings]
Combat_Block = LB
Player_Focus_Mode = LT
Combat_Abilities = LT
Combat_Attack = RB
Player_Abilities_Gamepad = RB
Player_Shadowstep = RT
```

The included INI lists every supported action and the current mod defaults. Values are case-insensitive:

| INI value | Physical control / PlayStation equivalent |
| --- | --- |
| A, B, X, Y | Cross, Circle, Square, Triangle |
| LB, LT, RB, RT | L1, L2, R1, R2 |
| LS, RS | Stick clicks / L3, R3 |
| View, Menu | Back/View or touchpad; Start/Menu or Options |
| DPadUp, DPadDown, DPadLeft, DPadRight | D-pad directions |
| LeftStick, RightStick | Two-dimensional stick axes; movement/camera only |
| RightStickLeft, RightStickRight | Right-stick directions used for target switching |

The equivalent full `Gamepad_*` names are also accepted. Each entry names the physical control to press, not another action. Assign both `Player_Hub_Map` and `Player_Hub_Launch` to the same button to retain their shared short-press/long-press shortcut. Their 0.30-second timing and the 0.90 walking threshold remain fixed.

Several actions intentionally share buttons in different contexts. Keep paired actions consistent where appropriate: Focus Mode/Combat Abilities, Attack/Overworld Abilities, and the two hub shortcuts. Assigning two simultaneous actions to one button can trigger both; the mod does not invent new chords or resolve those conflicts. Menu confirm/cancel navigation outside the preset is not configurable here. Movement/camera require stick axes, and button actions cannot use those axes.

Missing entries use this mod's defaults. Unknown settings, unknown controls, duplicate entries and incompatible axis assignments reject the whole file and leave the packaged layout in effect. `[General] Enabled = false` disables only INI remapping; the packaged shoulder/trigger swap, walking and hub changes remain. `DebugLogging = true` reports updates in `ue4ss/UE4SS.log`. Search the log for `[ControllerTweaks]` if controls do not change.

## Compatibility

Replaces `IA_Move`, `IA_Hub_Launch`, `IA_Hub_Map`, and `RIP_GamepadDefault`. Other mods changing these assets need a compatibility patch, even if Vortex shows no file conflict. Other runtime controller remappers can also compete with the INI settings.

Earlier standalone shoulder/trigger and TapMapHoldMenu/controller compatibility mods are superseded; disable them through Vortex. This mod has its own UE4SS directory and no HUDTweaks overrides. All three `zzz_DawnwalkerControllerTweaks_P` container files must come from the same release.

Based on Steam build **25129649 / CL-257186**. Later versions are unverified. The existing packaged controller behavior is unchanged. **INI remapping is a prerelease feature with offline validation; in-game acceptance is pending.** The game's cached button prompts or controller-layout screen may show the original preset even when a runtime binding changes; verify the actual action in game. Game and Steam Input deadzones affect the walking range.

Original mod work is licensed under [MIT](LICENSE.txt). Game assets belong to their respective rightsholders and are not relicensed.
