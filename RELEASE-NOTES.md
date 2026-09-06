# Dawnwalker Controller Tweaks v1.4.1

The INI now contains the complete configurable layout: all 31 actions with plain-language descriptions, all 20 supported key values with Xbox/PlayStation equivalents and full Unreal names, and guidance on stick clicks, axes, shared buttons and short press / long press behavior.

This is a documentation update. Binding values, Lua runtime files and cooked game assets are unchanged from v1.4.0.

## Updating and configuration

Back up your personal INI. Close the game, replace/reinstall the existing Vortex mod entry from Dawnwalker-Controller-Tweaks.zip as Root (game folder), and deploy. Keep one enabled Controller Tweaks entry. The ZIP includes a complete default INI; replacement does not merge preferences. Transfer your chosen values into the new commented file.

Open the mod folder through Vortex and edit Dawnwalker/Binaries/Win64/ue4ss/Mods/DawnwalkerControllerTweaks/Scripts/ControllerTweaks.ini. Deploy and restart after changes. A Dawnwalker-compatible UE4SS build with TMap and LoopInGameThreadWithDelay is required (reference: 3.0.1 Beta, 97b7e501c). Use the default controller preset. HUDTweaks is not required; older standalone controller/Map-shortcut mods should remain disabled.

## Validation

The documented INI parses to the same 31 bindings and general settings as v1.4.0. All supported aliases and full key names are documented. The actual ZIP, Vortex destination planning and cooked-container round-trip are verified before publication.

This remains a prerelease because v1.4.0 runtime remapping still awaits in-game acceptance. Test custom bindings after restarting and loading a save. The game's cached prompts/layout screen may retain the original labels. Existing walking and short-press/long-press behavior is unchanged.
