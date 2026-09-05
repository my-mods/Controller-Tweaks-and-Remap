# Controller Shoulder/Trigger Swap + map shortcut Compatibility

Reproducible UE5.5 IoStore compatibility mod for The Blood of Dawnwalker. It combines:

- the patch-257186 Tap View/Back for Map and Hold View/Back for Game Hub behavior;
- a global default-layout physical-key swap: `LB <-> LT` and `RB <-> RT`.
- v1.1.0: press Start/Options to reveal the compass through HUDTweaks.

A normal press reveals the compass immediately. It uses HUDTweaks' idleAfterSeconds,
fadeOutSeconds and idleOpacity, then returns to normal automatic visibility. Another
press refreshes the timer; holding does not repeat. Other HUD elements keep fading.
The original Start action is not consumed, so a press can also open its menu/legend.
