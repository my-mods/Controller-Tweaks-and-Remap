# Controller Tweaks and Remap

![Controller Tweaks and Remap](Nexus/thumbnail.jpg)

More comfortable controller input for The Blood of Dawnwalker on PC: swap shoulders and triggers, make walking easier, and open the Map or Game Hub with a short press or long press of the same button.

## Features

### Configurable controller mappings

Configure all 31 Default and Alternative controller bindings through Mod Settings. Choose a button or inherit the selected preset, press Apply to save and update the active game. The main file keeps the existing layout by default.

### Linked Voracious Bite controls

Player_Drink_Blood controls both starting Bite in Focus and holding to feed. Necrospeak in Focus shares this button. Normal Interact retains its own binding; Death from Above follows Attack. Default uses X/Square; Alternative uses LB/L1 to avoid Attack on X/Square. With Alternative, select LB/L1 or Inherit preset for Player Drink Blood. Keep Bite different from Attack and Focus. Keyboard Focus Bite/Necrospeak also follow the game's Drink Blood key.

### Controller stutter fixes

Stops completed background checks and combines duplicate input events so they do not repeatedly restart controller updates. Larger updates are spread across frames, and controls recover when needed after loading or controller preset changes. Settings apply during play and after save loads, with recovery for delayed player initialization and missed loading notifications.

### Linked actions and Focus controls

Controller overrides update every linked action in the active input profile, including Focus actions without a stored physical key. Focus actions take priority over ordinary interaction while Focus is active. Attack and the controller ability wheel can use different buttons. Keyboard bindings retain their separate profile slot.

### Shoulder / trigger swap

Swaps LB with LT and RB with RT in the default controller preset. PlayStation equivalents are L1 with L2 and R1 with R2.
- **Block:** LT / L2.
- **Focus Mode / Combat Abilities:** LB / L1.
- **Attack / Overworld Abilities:** RT / R2.
- **Shadowstep:** RB / R1.

The swap also applies in Photo Mode.

### Easier walking

Gives you a wider stick range for walking. Shapeshift and Mercurial Fervour stay active when you steer with the stick fully pushed. Sprint bindings are preserved.

### Short press Map / long press Game Hub

On Back/View (PlayStation touchpad):
- **Short press:** open the Map.
- **Long press (0.30 seconds):** open the Game Hub.

## Requirements

- **UE4SS — choose one:** [UE4SS for BoD by Framecore (2b or later)](https://www.nexusmods.com/thebloodofdawnwalker/mods/283) OR [UE4SS for Dawnwalker by Vercadi (RC6 or later)](https://www.nexusmods.com/thebloodofdawnwalker/mods/18).
- **Also required:** [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).

## Installation

- **Vortex:** Install Controller-Tweaks-and-Remap.zip through Vortex, enable it and deploy.
- **Manual:** Copy the archive's Dawnwalker folder into ...\steamapps\common\The Blood of Dawnwalker\, preserving the folder structure.

## Configuration

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Only affected bindings are queued. Validated presets, aliases and context indices are reused, and each changed context is rebuilt once. Logging changes do not inspect or rebuild mappings. Turning runtime remapping Off conditionally restores owned bindings.

Logging is the final, sole diagnostic control. It changes immediately; verbose logging is Off by default. Logs are written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Settings are never polled.

Settings are prepared at startup. Open **Main Menu > Mod Settings > All Mods > Controller Tweaks and Remap**. Choose your controls, press **Apply** to save and update the active game. Restore discards unapplied changes; Reset selects this mod's defaults.

Choose **Inherit preset** to use the selected Default or Alternative layout for a binding. Keep Player Hub Map and Player Hub Launch on the same control for the shared shortcut. Keep Player Drink Blood different from Attack and Focus. Cached button prompts may retain their previous labels.

### Original shoulder buttons

Use Mod Settings to select Block LB/L1, Focus Mode and Combat Abilities LT/L2, Attack and Overworld Abilities RB/R1, Shadowstep RT/R2, and Photo Mode rise/fall RT/R2 and LT/L2. Walking and Map/Game Hub tweaks remain active. These choices are included in the main download.

### Logging

Logging is the final setting and the only diagnostic control. It defaults to Off; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`

See SETTINGS.md and INPUT-BINDINGS.md in the archive for the complete settings and linked-action reference.

## Credits and source

Mod by CamilleBC. Controller and input changes are maintained in [Controller Tweaks and Remap on GitHub](https://github.com/my-mods/Controller-Tweaks-and-Remap). Bundled MIT-licensed Lua helpers come from [ue4ss-common](https://github.com/my-mods/ue4ss-common). Thanks to the UE4SS contributors, Framecore, Vercadi and the Mod Setting Menu author. Game assets belong to their respective rightsholders.

## License

Original mod work is licensed under the [MIT License](https://github.com/my-mods/Controller-Tweaks-and-Remap/blob/main/LICENSE.txt). Preserve the copyright and permission notices when reusing it. Underlying game assets are not relicensed under MIT and remain subject to their rightsholders' terms.
