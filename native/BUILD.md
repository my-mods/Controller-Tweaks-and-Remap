# Building the item input helper

Use Windows x64, Visual Studio 2022 MSVC v143, Windows SDK 10.0.26100.0 and CMake 3.25 or newer. Build Release with the shared C runtime.

The SDK uses RE-UE4SS `97b7e501c19d8b2b7c662feee73aaa0dc1f0a4d1` and its UEPseudo submodule `eb40a05f49509bdeb1ac39287032b60af585cca8`. The engine headers require an Epic-linked GitHub account; they are not redistributed here.

```bat
git clone https://github.com/UE4SS-RE/RE-UE4SS.git RE-UE4SS
git -C RE-UE4SS checkout 97b7e501c19d8b2b7c662feee73aaa0dc1f0a4d1
git -C RE-UE4SS submodule update --init deps/first/Unreal
cmake -S native -B build-native -A x64 -DUE4SS_SDK=C:/path/to/RE-UE4SS
cmake --build build-native --config Release
```

Run the CMake commands from this repository. Pinned MinHook, static Zydis/Zycore and SDK header dependencies are obtained by CMake. The resulting `main.dll` belongs in `Dawnwalker/Binaries/Win64/ue4ss/Mods/DawnwalkerControllerTweaks/dlls/` inside the archive. `UE4SS.def` creates an import library for the running UE4SS host; it is not a replacement host DLL. Preserve `LICENSES/MinHook.txt`, `LICENSES/Zydis.txt` and `LICENSES/Zycore.txt`.

## Input handling

The Lua adapter hooks the native `InventoryQuickslotSubsystem:TriggerQuickslot` function, which is separate from ability quickslot input. Controller D-pad item presses are acknowledged and held until release. A release within approximately 0.6 seconds invokes the original item operation once; longer holds cancel item use. The game still owns item availability, restrictions, consumption and cooldowns. Input is sampled every 16ms only while a candidate press is active, so boundary classification follows frame scheduling. Keyboard presses and other controller buttons retain their usual item behavior.

The helper resolves the implementation from the reflected function's native wrapper. It checks the Slot and result enum identities and meanings, scalar byte layout, full-width owner/result pointers, frame-owned argument-read destination, direct owner/Slot call and final AL result delivery. Overlapping stack writes invalidate the affected argument or saved-pointer facts, including non-MOV writes and uncertain/indexed aliases; proven MOV transfers and unrelated stack writes remain allowed. Later overlapping Result writes or an unclassified cleanup call receiving its pointer invalidate delivery until another proven AL store; unrelated cleanup remains allowed. MinHook validates that the actual target entry can be hooked. Reachable argument-transfer paths are checked without comparing engine helper bodies as a whole; the actual reflected Slot property-copy virtual entry and the host's named virtual-slot ABI identify a reachable compiled-copy path. This metadata is optional for wrappers using only the proven Frame bytecode reader; its DATA export is resolved dynamically from the already loaded host, not statically imported. It is required only when the reached argument-transfer route uses the copy interface. Specializations for other property classes are not requirements for this byte-enum Slot. Direct copy calls must target the actual reflected copy entry and retain its Property/destination/Locals ABI; its implementation and accessor/cleanup bodies execute normally and are not compared. The original implementation body and epilogue are not compared with a development binary, and wrapper cleanup continues normally. It does not gate by storefront, engine version or whole-file hash. Unsupported layouts disable only item input handling, with a diagnostic.

Suppression belongs to a bounded, thread-local stack during the synchronous reflected call. Tokens validate nesting; only the matching subsystem address and slot are suppressed. Addresses are comparison values and are never dereferenced or retained by the native helper across frames. The Lua adapter owns revalidation of world, controller, pawn and item subsystem while a press is pending; loading, remapping, pause, disabled item quickslots or replaced owners cancel it. Completed input leaves no timer running.

An optional numeric shared-variable contract coordinates accepted Down holds with Ignite's controller customization. No UObject, Lua function, coroutine or borrowed engine value crosses mod states. Ignite calls the game's native torch toggle once for an accepted hold and continues to work independently without this adapter. Logging uses the existing final Logging control; input counts and aggregate Lua CPU timings are collected only when enabled.
