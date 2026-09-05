# Dawnwalker Controller Tweaks

Controller improvements for **The Blood of Dawnwalker (PC)**, packaged for Vortex.

## Download and install

Download the mod ZIP from [Releases](https://github.com/my-mods/Dawnwalker-Controller-Tweaks/releases).
Do not install GitHub's automatically generated source-code ZIP as a mod.

Requires HUDTweaks v2, a Dawnwalker-compatible UE4SS installation with
`LoopInGameThreadWithDelay` (present in the diagnosed build 97b7e501), and the default
controller layout. Built against Steam build 25129649 / executable CL-257186;
compatibility with later game or HUDTweaks versions is not established.

1. Close the game and import the release ZIP into Vortex.
2. Replace earlier Controller Swap / Controller Tweaks packages and disable the
   original menu-shortcut and menu-shortcut mods.
3. Keep HUDTweaks enabled; let this mod win its `Scripts/main.lua` conflict.
4. If using [HUDTweaks Prompt Dismissal Fix](https://github.com/my-mods/Dawnwalker-HUDTweaks-Prompt-Fix),
   keep that fix enabled and winning `Scripts/HUDTweaks.ini`.
5. Enable and deploy through Vortex using the Root (game folder) mod type.

This repository does not deploy files into your game. Disable this mod in Vortex
and redeploy to uninstall. The previous HUDTweaks main.lua then becomes active.

In-game validation remains pending; this release is a prerelease.

## Stable identity

This is the stable name for this controller mod. New features change the version
and changelog, not the name. Every build overwrites `Dawnwalker-Controller-Tweaks.zip`.
The ZIP filename never contains a version or game build. Version metadata remains in
`package/mod.manifest` and GitHub release tags; use Vortex's replacement/update flow
for the same mod entry instead of creating another named variant.
The legacy internal mod ID, container filenames, and repository folder are retained
to avoid changing existing paths. Version 1.1.5 fixes lookup failure recovery and
uses one persistent game-thread timer for compass input.

Reproducible UE5.5 IoStore compatibility mod for The Blood of Dawnwalker. It combines:

- the patch-257186 Tap View/Back for Map and Hold View/Back for Game Hub behavior;
- a global default-layout physical-key swap: `LB <-> LT` and `RB <-> RT`.
- v1.1.0: press Start/Options to reveal the compass through HUDTweaks.

A normal press reveals the compass immediately. It uses HUDTweaks' idleAfterSeconds,
fadeOutSeconds and idleOpacity, then returns to normal automatic visibility. Another
press refreshes the timer; holding does not repeat. Other HUD elements keep fading.
The original Start action is not consumed, so a press can also open its menu/legend.

## Credits and reporting issues

This is an unofficial compatibility mod, not the original HUDTweaks project.
HUDTweaks and captured game assets belong to their respective authors/rightsholders;
their inclusion does not grant a new license to those components.

When reporting a problem, include the game build, mod versions, Vortex conflict winners,
and relevant ControllerCompass log lines. Review logs for private information before posting.

## Vortex metadata and updates

The metadata added in v1.1.4 generates `vortex_override_instructions.json` from `mod.manifest`, so Vortex sets the display name, version, and description during installation. These metadata instructions preserve the payload destinations.

Replace/reinstall the updated ZIP through Vortex using the existing mod entry, then deploy. Redeployment alone cannot read new archive metadata. This does not provide automatic update discovery or merge duplicate Vortex entries.

Archive filename: Dawnwalker-Controller-Tweaks.zip
