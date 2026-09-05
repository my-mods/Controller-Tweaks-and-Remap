# Dawnwalker Controller Tweaks

Controller improvements for **The Blood of Dawnwalker (PC)**, packaged for Vortex.

- LB <-> LT (PlayStation L1 <-> L2) and RB <-> RT (R1 <-> R2), in both directions.
- Wider left-stick walking range: the existing walk-to-run threshold changes from 0.70 to 0.90.
- Tap Back/View (PlayStation touchpad) for Map; hold 0.30 seconds for Game Hub.

**Version 1.3.0 removes the nonfunctional Start/Options compass feature. No other
mods are required: HUDTweaks and UE4SS are no longer dependencies.**

## Download and install

Download **Dawnwalker-Controller-Tweaks.zip** from
[Releases](https://github.com/my-mods/Dawnwalker-Controller-Tweaks/releases).
Use the mod archive, not GitHub's source-code ZIP.

### Updating from 1.2.1 or earlier

1. Close the game. Disable the previous Controller Tweaks entry in Vortex and deploy
   so Vortex removes its old HUDTweaks script overrides.
2. Import Dawnwalker-Controller-Tweaks.zip and replace/reinstall that same mod entry
   from the new archive. Use replacement, not a merge that retains old files.
3. Select Root (game folder), enable the replacement, and deploy through Vortex.
   Redeploying the old entry alone does not process the new archive.
4. Keep one Controller Tweaks entry. Earlier standalone menu-shortcut,
   menu-shortcut and Controller Swap variants remain superseded.

The new package has no HUDTweaks main.lua conflict. If you keep HUDTweaks for its
own features, its original Scripts/main.lua should become active again; Vortex
should remove ControllerCompass.lua from the old package. If you use Prompt
Dismissal Fix, it remains independent and still wins HUDTweaks.ini. Do not remove
HUDTweaks or UE4SS if other mods still need them. Manage all cleanup through Vortex.

For a first installation, import the ZIP as **Root (game folder)**, enable and
deploy. To uninstall, disable/remove Controller Tweaks and deploy through Vortex.

## Controls and compatibility

The physical-key swap applies globally to the default controller preset, including
Photo Mode. Block moves to LT, Focus Mode/Combat Abilities to LB, Attack/Overworld
Abilities to RT, and Shadowstep to RB. The remaining Start/Options behavior is the
game's own behavior.

The walking threshold uses processed movement input; the game's and Steam Input's
deadzone/sensitivity settings affect physical stick travel. Full-tilt input,
direction, sprint bindings, camera and keyboard mappings are preserved. IA_Move
is a shared movement action. No delay, movement Lua hook or replacement INI is added.

Built from Steam build 25129649 / executable CL-257186 stock assets. Compatibility
with later game versions is not established. Replaces exactly IA_Move,
IA_Hub_Launch, IA_Hub_Map and RIP_GamepadDefault. Another cooked mod replacing these
assets needs a compatibility patch. Differently named containers can conflict
without a Vortex file warning; file conflict rules cannot merge their assets.
For identical container filenames, Controller Tweaks must win all three files.

## Stable identity

Keep one Vortex entry and use its replace/update flow. The display name, legacy
internal ID, container paths and **Dawnwalker-Controller-Tweaks.zip** remain stable.
Versions live in the manifest, source metadata and release tags. Vortex override
metadata sets the name, version and description when the ZIP is processed; it
does not provide automatic update discovery or merge existing duplicates.

In-game validation remains pending; this release is a prerelease.

## Provenance

Captured game assets belong to their rightsholders. Stock snapshots, hashes and
capture provenance are retained in SOURCE.json. The removed compass integration
is recoverable in Git history. upstream/HUDTweaks/main.lua and retiredCompass
metadata remain only as a historical source/provenance record; they are neither
built nor shipped. No new license is granted to third-party components.

When reporting issues, include the game build, mod version, Vortex conflict winners
and observed controls. See [release notes](RELEASE-NOTES.md).
