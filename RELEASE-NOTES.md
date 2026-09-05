# Dawnwalker Controller Tweaks v1.1.4

The ZIP now generates vortex_override_instructions.json from mod.manifest, so Vortex sets the display name, version, and description during installation. Runtime payloads and file destinations are unchanged.

Replace/reinstall the updated ZIP through Vortex using the existing mod entry, then deploy. Redeployment alone cannot read new archive metadata. This does not provide automatic update discovery or merge duplicate Vortex entries.

Archive filename: Dawnwalker-Controller-Tweaks.zip

Validation: ZIP allowlist, manifest/attribute agreement, UTF-8 without BOM, installed Vortex attribute merge, and installer destination planning. Lua and INI hashes match the previous local release. All three cooked assets match after round-trip extraction; container serialization order can differ. 

No live Vortex installation/deployment or in-game test is performed for this packaging update. Confirm the displayed name, version, and description after reinstalling. Previous in-game acceptance checks remain applicable.

Requires HUDTweaks v2 and UE4SS. Keep HUDTweaks enabled. Controller Tweaks wins Scripts/main.lua; Prompt Dismissal Fix wins Scripts/HUDTweaks.ini. Disable standalone menu-shortcut/controller compatibility variants through Vortex. Use Root (game folder). Native compass checks remain pending; this is a prerelease.

Verified local archive: 54959 bytes; SHA-256 `99C2266E3EF4A50D7273526152B9C5FBCAFE9DABB068938A6CF68B88593B8720`.
