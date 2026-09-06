DAWNWALKER CONTROLLER TWEAKS - ORIGINAL SHOULDER BUTTONS
Optional personal INI preset, version 1.4.0

Requires the main Controller Tweaks and Remap 1.4.0 mod, compatible UE4SS,
and the game's default controller preset. This download contains no loader
or cooked mod assets. Install the main mod through Vortex first.

This preset restores the original LB/LT and RB/RT bindings (L1/L2 and R1/R2),
including Photo Mode. Short press Map / long press Game Hub
remain supplied by the main mod. Quickslots and other bindings inherit its
defaults. The INI includes the full commented layout and supported key names.

INSTALL / UPDATE - MANUAL DOWNLOAD ONLY
1. Launch the game once with Controller Tweaks 1.4.0, then close the game.
2. Open %LOCALAPPDATA%\Dawnwalker\Saved\Config in File Explorer.
3. Back up your existing ControllerTweaks.ini before applying this preset.
4. If you have no personal settings to keep, copy this download's
   ControllerTweaks.ini into that folder. Replacing the file replaces all
   existing preferences; it does not merge them.
5. To preserve other settings, edit your existing file instead: set Enabled
   to true under its existing [General] section, then copy/update the eight
   active bindings below under its existing [Bindings] section. Replace an
   existing line for the same action; do not add duplicate active entries.
6. Save and restart the game. Personal INI changes need no Vortex deployment.

Do not import this optional archive into Vortex or extract it into the game
folder. It is a personal profile preset, not a separately installed mod.
The main mod's updates do not replace this personal INI.

[General]
Enabled = true

[Bindings]
Combat_Block = LB
Player_Focus_Mode = LT
Combat_Abilities = LT
Combat_Attack = RB
Player_Abilities_Gamepad = RB
Player_Shadowstep = RT
Photo_Vertical_Rise = RT
Photo_Vertical_Fall = LT

CONTROLS
Block: LB / L1
Focus Mode and Combat Abilities: LT / L2
Attack and Overworld Abilities: RB / R1
Shadowstep: RT / R2
Photo Mode rise: RT / R2; fall: LT / L2

REMOVE THIS PRESET
Comment out or remove only the eight binding overrides above, then restart.
They will inherit the main mod's shoulder/trigger swap again. Keep any other
personal settings you want. Setting Enabled=false is not an undo for the
packaged swap; it disables INI remapping and leaves the cooked swap active.

VALIDATION AND COMPATIBILITY
The eight bindings are checked against the preserved original controller
preset. INI parsing and archive contents are checked offline. Runtime
remapping and this optional preset still require an in-game check, including
after loading a save. Cached prompts may continue showing the old labels.
This preset changes bindings only; it does not change triggers or modifiers.

Source: https://github.com/my-mods/Dawnwalker-Controller-Tweaks-and-Remap
Original mod work is MIT-licensed; see LICENSE.txt.
