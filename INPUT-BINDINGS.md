# Input bindings

Edit `%LOCALAPPDATA%/Dawnwalker/Saved/Config/ControllerTweaks.ini`, then restart the game. The remapper applies the selected Default or Alternative layout and your active overrides to the controller profile. It updates every linked action reported by the game, including actions with no physical key stored in their input context. Keyboard settings remain separate.

## Linked controls

| INI setting | Actions controlled together |
| --- | --- |
| `Combat_Attack` | Attack, Death from Above, drawing the weapon with the attack button |
| `Combat_Block` | Block and drawing the weapon with the block button |
| `Combat_Dodge` | Dodge and combat sprint |
| `Player_Interact` | Ordinary interaction and ledge look interaction |
| `Traversal_Jump` | Jump and ladder drop |
| `Traversal_Crouch` | Crouch, ladder slide and ability cancel |
| `Camera_Look` | Normal camera and Photo Mode look |
| `Traversal_Movement_Axis` | Normal movement and Photo Mode movement |
| `Player_Drink_Blood` | Feeding, Focus Voracious Bite and Focus Necrospeak |
| `Player_Abilities_Gamepad` | Controller overworld ability wheel |

These links follow the game's action definitions. There is no separate Death from Above binding. The keyboard ability wheel is a different action, configured in the game's keyboard settings; changing that key does not configure the controller wheel.

## Shared buttons

The game intentionally reuses buttons across gameplay contexts. Its configuration conflict groups distinguish General, Combat, Blood Drinking and Photo Mode controls. A shared button can be valid in separate modes but conflict when both actions become active together.

The experimental package gives Focus priority over ordinary interaction while Focus is active. With Alternative, Attack and Interact can retain X; the Focus Attack action takes precedence over ordinary interaction. Outside Focus, Interact keeps its configured button. This context priority also applies to keyboard mappings when keyboard controls share a key across those contexts.

Keep Bite different from Attack and the Focus activation button. Avoid assigning the wheel to the button held to enter Focus. Two actions inside Focus sharing a button can both receive input; priority between contexts does not separate actions within the same context. The remapper preserves the game's press, hold and release triggers rather than adding chords or choosing one action arbitrarily.

Attack and the wheel do not need matching buttons. For example:

```ini
[Bindings]
Combat_Attack = X
Player_Abilities_Gamepad = RT
Player_Interact = X
Player_Drink_Blood = LB
Player_Focus_Mode = LT
```

Keep `Player_Hub_Map` and `Player_Hub_Launch` together to retain the Map short press and Game Hub long press shortcut. All accepted keys and 31 settings are described in `ControllerTweaks.defaults.ini`.

## Diagnostics

Set `debugLogging = true` under `[General]` in the personal INI and restart. Search `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log` for `[ControllerTweaks]`. Messages include verified profile-update counts, bounded setup timings and Focus priority adjustments. Missing profile slots or rejected writes produce a named error and stop the current setup instead of repeatedly retrying a failed write. Set `debugLogging = false` to turn detailed logging off.

The remapper does not save the game's input settings. Setup and relevant input lifecycle events trigger bounded work; it does not continuously poll bindings. Existing personal INIs are not replaced to update reference comments.
