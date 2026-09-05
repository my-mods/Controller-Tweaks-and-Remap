# Changes

## 1.3.1 — 2026-09-05

- Use Controller Tweaks identifiers and container filenames.
- Preserve all controller behavior.

## 1.3.0 — 2026-09-05

- Remove the reported nonfunctional Start/Options compass reveal and its Lua adapter.
- Remove HUDTweaks and UE4SS dependencies; ship only the existing container triple.
- Preserve shoulder/trigger swap, map and hub shortcuts and the wider walking range.
- Document Vortex replacement to remove old script overrides and restore HUDTweaks.
- Retain historical upstream provenance.
- Keep stable mod identity and archive name; include only the seven required package files.

## 1.2.1 — 2026-09-05

- Put the complete feature list at the top of both READMEs: bidirectional LB/LT
  and RB/RT swaps, walk-to-run threshold, map and hub shortcuts, compass reveal/fade,
  and the included compass loading recovery fix.
- Document PlayStation equivalents and correct the packaged asset list to include
  IA_Move. Clarify shared-asset compatibility and processed-input threshold scope.
- Documentation/metadata only; all five gameplay files are byte-identical to v1.2.0.

## 1.2.0 — 2026-09-05

- Widen the left-stick walking range by raising IA_Move's existing MoveFast
  modifier threshold from 0.70 to 0.90; preserve direction and full-tilt input.
- Include the v1.1.5 compass loading/polling fix and all earlier controller tweaks.

- Keep the same mod name, identity, deployment paths and ZIP filename.
- Prerelease: package/offline validation only; in-game movement testing remains.

## 1.1.5 — 2026-09-05

- Replace repeated async-to-game-thread callback registration with one persistent
  game-thread timer, available in the diagnosed UE4SS build (97b7e501).
- Replace the HUDTweaks gameplay-pawn adapter with a lookup that validates returned
  tables and local controller possession, including retained menu controllers.
- Recover from transient lookup/input errors and rearm only after button release.

- Offline regression and packaging validation only; in-game retest required.

## 1.1.4 — 2026-09-05

- Generate Vortex display name, version, and description in the release archive.
- Preserve the existing ZIP filename and runtime payloads. Reinstall/replace through Vortex to read metadata.

## 1.1.3 — 2026-09-05

- Rename the Data layout note to Dawnwalker-Controller-Tweaks-PACKAGE-LAYOUT.txt.
- Exclude the old shared note from archives.
- Keep the stable ZIP filename and existing runtime behavior.

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
