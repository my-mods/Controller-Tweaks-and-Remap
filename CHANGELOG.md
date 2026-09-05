# Changes

## 1.1.0 — 2026-09-05

- Standardized the display name to Dawnwalker Controller Tweaks. Archive names now
  use a stable prefix and the manifest version; internal IDs and deployed paths stay
  unchanged. The naming-only repackage retains 1.1.0 and identical gameplay behavior.

- Added normal Start/Options press to reveal the compass; no long hold is required.
- Integrated compass state into HUDTweaks' opacity calculation for the strip, headings,
  and pins, preserving all other HUD settings and protecting widget class defaults.
- Reveal follows the live HUDTweaks idle/fade settings, then returns to normal behavior.
- Subsequent clicks refresh the timer; there is no persistent visibility toggle.
- Added release-to-rearm protection after startup, controller changes, stalls and errors.
- Preserved the existing Start action; a press can also open its menu/legend.
- Changed the mixed Lua/PAK archive to Vortex's game-root layout with no duplicate payload.
- Retain the original HUDTweaks source snapshot.
- Game-native binding and visuals still require an in-game check after Vortex deployment.
