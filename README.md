# Dawnwalker Controller Tweaks

Controller improvements for **The Blood of Dawnwalker (PC)**, packaged for Vortex.

## Included controller changes

Every release contains all of these changes in one Controller Tweaks package:

| Control | Behavior with this mod |
| --- | --- |
| LB / LT (PlayStation L1 / L2) | Swapped both ways: LB actions use LT, and LT actions use LB. |
| RB / RT (PlayStation R1 / R2) | Swapped both ways: RB actions use RT, and RT actions use RB. |
| Left stick: walking to running | Fast-movement threshold raised from **0.70 to 0.90**, giving walking more stick travel. Full-tilt input is preserved. |
| Xbox Back/View / PlayStation touchpad | Tap to open the map; hold for **0.30 seconds** to open Game Hub. |
| Xbox Start/Menu / PlayStation Options | Press to reveal the compass, then let it fade using your HUDTweaks idle/fade settings. Press again to refresh the timer; holding does not repeat. |

The shoulder/trigger swap applies throughout the default controller preset,
including Block (LB -> LT), Focus/Combat Abilities (LT -> LB),
Attack/Overworld Abilities (RB -> RT), Shadowstep (RT -> RB), and Photo Mode
rise/fall. Keyboard bindings are unchanged.

The walk-to-run threshold uses processed movement input. Game and Steam Input
deadzone/sensitivity settings affect the physical stick position; **0.90 does not
mean a guaranteed 90% physical-stick position**. No input delay is added.

Compass reveal is temporary, not a permanent visibility toggle. Start/Options
still performs its original menu/controls-legend action. The included v1.1.5 fix
also validates the gameplay controller after loading and retries transient lookup
or input failures. Native movement feel and compass behavior still need testing.

Version 1.2.1 clarifies both READMEs; gameplay payloads are unchanged from v1.2.0.

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
