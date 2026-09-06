# Dawnwalker Controller Tweaks v1.4.0

- Configure all 31 default-preset controller bindings in ControllerTweaks.ini, using Xbox-style aliases or full Unreal gamepad key names.
- Read the INI at startup and reapply changed bindings when the game recreates its input contexts. Preserve keyboard/mouse keys and existing triggers/modifiers.
- Keep the previous controller layout as the default, including Photo Mode, the 0.90 walking threshold and short press Map / long press Game Hub.
- Reject invalid configuration files instead of applying a partial layout.

## Updating through Vortex

INI remapping adds a UE4SS dependency. Install a Dawnwalker-compatible UE4SS build with the TMap and delayed game-thread APIs (reference: 3.0.1 Beta, 97b7e501c). The loader is not included; HUDTweaks is not required.

Close the game, back up any personal INI, replace/reinstall the existing Controller Tweaks entry from Dawnwalker-Controller-Tweaks.zip, and deploy. Reinstall the archive so Vortex processes the added UE4SS files. Use Root (game folder) and keep one enabled entry. Select the default controller preset. The included INI is a full default configuration, not a merge of your preferences.

The three zzz_DawnwalkerControllerTweaks_P containers are unchanged. Keep older standalone controller/Map shortcut mods disabled. No HUDTweaks files are overridden. For upgrades from pre-1.3.0, disable the old entry and deploy before replacement so Vortex removes ControllerCompass.lua and restores HUDTweaks' main.lua if HUDTweaks is enabled.

## Validation and remaining checks

Prerelease: Lua 5.4 configuration and mocked runtime regression checks pass for startup, missing/invalid configuration, simultaneous swaps, key-cache replacement, keyboard and trigger preservation, repeated application, save-load/context recreation, and possession/subsystem replacement. The 31 supplied bindings match the cooked preset. Actual ZIP bytes, repeated stable builds, installed Vortex destination planning and container round-trip are checked before publication.

In-game acceptance is still required: change a combat binding, restart, test it in gameplay and Photo Mode, load a save, and verify short/long press shortcuts and stick controls. Check UE4SS.log for [ControllerTweaks] errors. The game's cached prompts/layout screen may retain the preset labels; runtime prompt synchronization is not guaranteed. Live-game testing was not performed for this release.
