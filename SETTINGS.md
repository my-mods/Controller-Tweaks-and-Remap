# Settings

Install [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. Settings are prepared at startup. Open Main Menu > Mod Settings > All Mods before or after loading a save. Select this mod, change settings and press Apply. **Apply updates the active game.** Restore discards unapplied changes; Reset selects this mod’s defaults.

The stable menu ID is `oOCamilleOo_ControllerTweaksAndRemap`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Settings files are read at startup and save-load boundaries; menu callbacks use committed values without file I/O. After startup preparation, waiting at the main menu performs no settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Runtime remapping | Off, On |
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
| Diagnostics | Logging | Off, On |

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.

**Logging** is the final menu setting and the only diagnostic control. Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

## Original shoulder buttons

Use these choices with the Default preset, press Apply to save and update the active game.

| Setting | Choice |
| --- | --- |
| Combat Block | LB / L1 |
| Combat Abilities | LT / L2 |
| Player Focus Mode | LT / L2 |
| Combat Attack | RB / R1 |
| Player Abilities Gamepad | RB / R1 |
| Player Shadowstep | RT / R2 |
| Photo Vertical Rise | RT / R2 |
| Photo Vertical Fall | LT / L2 |

Walking and Map/Game Hub tweaks remain active.

## Live Apply

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Only affected bindings are queued. Validated presets, aliases and context indices are reused, and each changed context is rebuilt once. Logging changes do not inspect or rebuild mappings. Turning runtime remapping Off conditionally restores owned bindings.
