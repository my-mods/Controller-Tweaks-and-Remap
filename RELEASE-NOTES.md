## Pending correction

Remove the Easier walking override to address reported Shapeshift/Mercurial Fervour interruption when steering. Movement returns to the original 0.70 threshold.

# Controller Tweaks and Remap v1.5.0

This minor update adds Alternative controller support and links the Bite controls. It also removes unnecessary background checks to address controller-related stutter.

## What changed

- Reduce controller-related stutter by stopping unnecessary background checks.
- Add support for the Alternative controller layout, including custom INI settings. Bite uses LB/L1 by default so it no longer shares X/Square with Attack.
- Use the Drink Blood binding both to start Voracious Bite and to keep feeding. Necrospeak uses the same button; keyboard users also use their Drink Blood key for these Focus abilities.
- Warn in the log when Bite and Attack share a button.

## Updating

Close the game. Replace/reinstall the existing Controller Tweaks and Remap entry in Vortex with Dawnwalker-Controller-Tweaks.zip as **Root (game folder)**, then deploy. Keep one enabled entry and restart the game after selecting Default or Alternative. Requires the separate Dawnwalker-compatible UE4SS loader (reference: 3.0.1 Beta, 97b7e501c). HUDTweaks is not required.

Your personal **%LOCALAPPDATA%\Dawnwalker\Saved\Config\ControllerTweaks.ini** is preserved. With Alternative selected, change an explicit `Player_Drink_Blood = X` to `LB`, or comment it out to use the new default. Avoid assigning Bite to the same button as Attack or Focus. If every entry in an older INI is active, comment out settings you want to inherit from the selected layout. Save and restart after editing.

The optional **Original Shoulder Buttons 1.4.0** download remains for the Default layout. Back up your personal INI before using it: replacing the whole file overwrites your preferences. Copy only its eight binding changes into your existing INI if you want to keep other settings. Do not install that optional preset through Vortex.

Older standalone controller and TapMapHoldMenu mods remain superseded. This release also changes **DA_FocusConfig**, so other mods changing that asset need a compatibility patch. All three zzz_DawnwalkerControllerTweaks_P files must come from this release. No HUDTweaks files are included.

If upgrading from an older package with a personal INI inside the mod folder, back it up before Vortex replacement and transfer your desired settings to the profile path above. Existing personal files are never overwritten by this mod.

## Compatibility

Based on Steam build **25129649 / CL-257186**. Existing shoulder/trigger and short-press Map / long-press Hub behavior is preserved. Button prompts and the controller-layout screen may still show the original bindings.
