# Dawnwalker Controller Tweaks

This is the stable name for this controller mod. New features change the version
and changelog, not the name. Releases use `Dawnwalker-Controller-Tweaks-VERSION.zip`,
with VERSION read from `package/mod.manifest`.
The legacy internal mod ID, container filenames, and repository folder are retained
to avoid changing existing paths. This naming correction keeps version 1.1.0;
gameplay behavior is unchanged.

Reproducible UE5.5 IoStore compatibility mod for The Blood of Dawnwalker. It combines:

- the patch-257186 Tap View/Back for Map and Hold View/Back for Game Hub behavior;
- a global default-layout physical-key swap: `LB <-> LT` and `RB <-> RT`.
- v1.1.0: press Start/Options to reveal the compass through HUDTweaks.

A normal press reveals the compass immediately. It uses HUDTweaks' idleAfterSeconds,
fadeOutSeconds and idleOpacity, then returns to normal automatic visibility. Another
press refreshes the timer; holding does not repeat. Other HUD elements keep fading.
The original Start action is not consumed, so a press can also open its menu/legend.
