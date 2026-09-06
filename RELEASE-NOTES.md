# Dawnwalker Controller Tweaks v1.4.0

## Pending development changes

The remapper now stops its worker after successful input setup. It caches input-system references and binding metadata, and wakes for loading, possession and input-context setup. Readiness retries are bounded. INI edits still require a game restart. This removes the repeated idle work; confirmation of a stutter fix and lifecycle-hook behavior still needs in-game testing. Version metadata remains 1.4.0.

The Drink Blood binding now controls both starting Voracious Bite in Focus and holding to feed. Necrospeak in Focus follows it as well. Normal Interact and Attack/Death from Above retain separate actions. This also links keyboard Focus Bite/Necrospeak to the game's Drink Blood key.

Alternative is now supported: its original layout is preserved except Bite/feeding defaults to LB/L1, separating it from Attack on X/Square. Active personal entries override either selected preset. If an old INI has `Player_Drink_Blood = X`, change it to `LB` or comment it out to inherit Alternative's default. An older INI with every binding active overrides the entire layout; comment out unwanted values. Keep Bite different from Attack and Focus.

The native change replaces `DA_FocusConfig` in addition to the four existing input assets. Any other mod changing that asset needs a compatibility patch. Disabling runtime remapping retains the native linked input but disables Alternative's LB default and personal overrides.

Configure all 31 controller bindings in Default or Alternative with an INI. The shipped ControllerTweaks.defaults.ini contains the complete layout, action descriptions, Xbox/PlayStation equivalents and all supported key names.

Personal overrides live at **%LOCALAPPDATA%\Dawnwalker\Saved\Config\ControllerTweaks.ini**, outside Vortex-managed files. Current shipped defaults load first; personal values take precedence. Omitted/commented settings inherit new defaults. The mod creates a commented reference only if the personal file is missing and never rewrites an existing personal file.

## Installation and update

Requires a Dawnwalker-compatible UE4SS build with TMap and LoopInGameThreadWithDelay (reference: 3.0.1 Beta, 97b7e501c). The loader is separate; HUDTweaks is not required. Import Dawnwalker-Controller-Tweaks.zip into Vortex as Root (game folder), replace/reinstall the existing entry if present, and deploy. Keep one enabled entry and select Default or Alternative, then restart the game. Older standalone controller and Map-shortcut mods remain superseded.

Launch once, close the game, then edit the personal INI. Uncomment only values you want to change and restart. Personal edits do not require redeployment. Reinstall this revised archive even if Vortex already displays 1.4.0 to receive the updated containers, remapper and binding documentation. Existing personal files are preserved, including old comments; consult the included ControllerTweaks.defaults.ini for the current reference.

## Migration from an INI inside the mod folder

Before replacing an older archive, back up the edited Scripts/ControllerTweaks.ini using Vortex's Open in File Manager. Vortex may remove that old file during replacement before the updated mod can read it.

With the game closed, copy that backup to %LOCALAPPDATA%\Dawnwalker\Saved\Config\ControllerTweaks.ini if no personal file exists. If one already exists, transfer only the desired settings manually; do not overwrite it. A full migrated INI preserves all its explicit values; remove or comment out entries you want to inherit from future defaults.

If a valid legacy Scripts/ControllerTweaks.ini is still present on first startup and the personal file is absent, the mod copies it byte for byte without changing the original. An existing personal file always wins. Invalid or unreadable files are preserved and reported in UE4SS.log rather than silently replaced. If the game's Saved/Config folder is not available yet, creation waits and retries.

## Validation

Offline tests cover layered defaults and partial overrides, preservation across repeated starts and simulated updates, empty/read-only/invalid personal files, first creation, legacy migration, concurrent creation, and startup/loading/possession behavior. Actual ZIP contents, stable repeat builds, installed Vortex destination planning and container round-trip are verified before publication. The archive contains no personal ControllerTweaks.ini.

Prerelease: in-game acceptance remains pending. Test custom bindings after restarting and loading a save; check [ControllerTweaks] messages in UE4SS.log. Cached prompts/layout labels may remain unchanged. Existing walking and short-press/long-press behavior is preserved. Test starting Bite and continuing the hold without releasing, both stages after rebinding, Necrospeak, normal Interact, Death from Above on Alternative X, keyboard behavior, prompts, and recovery after loading/possession. Alternative defaults and personal overrides pass offline tests, including 600 idle seconds without worker/API activity. The five cooked assets are checked from the actual ZIP.
