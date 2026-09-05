# Dawnwalker Controller Tweaks v1.3.4

Includes the existing MIT license text for the original mod work, with the underlying game assets remaining subject to their rightsholders' terms. This corrects the package documentation; it does not change the mod's license. All three runtime containers are unchanged from v1.3.3 and v1.3.1; controller behavior was previously confirmed working in game.

The Nexus thumbnail, full description and listing metadata remain separate in the repository's [Nexus folder](https://github.com/my-mods/Dawnwalker-Controller-Tweaks/tree/main/Nexus).

Import **Dawnwalker-Controller-Tweaks.zip** directly into Vortex 1.14 or newer as **Root (game folder)**. For an update, replace/reinstall the existing entry, then deploy. Updating from v1.3.1 is optional if you only want the gameplay changes. No other mods or loaders are required. Direct ZIP installation is validated; collection installation is not supported by this package's metadata exclusions.

For versions before 1.3.1, disable the old entry and deploy first, then replace/reinstall that same entry from this ZIP and deploy. Vortex must remove the previous container names. For versions before 1.3.0 it must also remove ControllerCompass.lua and restore original HUDTweaks main.lua if HUDTweaks remains enabled. Disable superseded standalone TapMapHoldMenu/controller compatibility mods through Vortex.

Validation: exact ZIP allowlist and source-byte comparison, absence of Nexus materials from the ZIP, unchanged runtime-container hashes, container verification and round-trip extraction, and read-only installer planning against the installed Vortex extension. Only the three runtime containers are planned for deployment. This packaging-only update does not change gameplay; later game builds remain unverified.
