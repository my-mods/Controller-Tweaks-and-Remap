# Changes

## 1.1.2 — 2026-09-05

- Use Dawnwalker-Controller-Tweaks.zip, without a version suffix.
- Keep version numbers in metadata and release tags; preserve one Vortex mod identity.
- Controller and compass behavior are unchanged from 1.1.1.

## 1.1.1 — 2026-09-05

- Fix a controller-cache bug that could keep a valid menu controller after gameplay
  possession, silently preventing all compass input polling.
- Select the local PlayerController possessing HUDTweaks' detected gameplay pawn,
  and revalidate possession before reusing a cached controller.
- Add waiting-state and selected-controller diagnostics.

- Preserve click-to-reveal behavior, idle fading, controller mappings, and mod identity.
- The v1.1.0 game log confirmed loading but no input-ready message; v1.1.1 needs a
  native retest after Vortex deployment.

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
