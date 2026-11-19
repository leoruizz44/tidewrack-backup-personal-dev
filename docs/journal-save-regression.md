# Journal save — regression checklist

Manual checks for the journal persistence change on
`fix/journal-save-persistence`: discovered journal ids are saved next to
`scene` and `flags`, restored on Continue, and cleared on New Game.

Run all five cases in the engine before merging. Each one starts from the
setup below.

## Setup

**1. Temporary debug keys.** Nothing in the game discovers journal entries yet
and there is no journal screen, so add this at the top of `_unhandled_input`
in `scripts/game.gd` for the duration of the test. Do not commit it.

```gdscript
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			Journal.discover("entry_test_a")
		elif event.keycode == KEY_F2:
			Journal.discover("entry_test_b")
		elif event.keycode == KEY_F3:
			print("journal: ", Journal.entries(), "  flags: ", GameState.flags)
```

- **F1 / F2** discover a test entry.
- **F3** prints the journal and the story flags to the Output panel.

**2. Find the save file.** In the editor: Project → Open User Data Folder.
The file is `save.json` in that folder:

| OS | Folder |
|----|--------|
| Windows | `%APPDATA%\Godot\app_userdata\Tidewrack\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Tidewrack/` |
| Linux | `~/.local/share/godot/app_userdata/Tidewrack/` |

**3. Ground rules.**

- Saving is manual: Esc → Save, and wait for the button to read "Saved ✓".
- "Esc" in a step means open the pause menu. If the menu is already open
  (for example straight after a Save), skip the Esc and pick the next button.
- `project.godot` binds the `ui_*` actions to gamepad input only. If Esc,
  Enter or the arrow keys do nothing, use a gamepad: B opens the pause menu,
  A interacts and advances dialogue, the left stick moves. Menu buttons can be
  clicked with the mouse, and the F1–F3 debug keys work either way.
- Story flags come from the ground-floor room: the logbook sets `skeptic` or
  `believer`, then `trusted_edith`; the radio sets `radioed_tom`.
- Where a step says **relaunch**, quit the game completely and start it again.
  Returning to the main menu keeps the old state in memory, so only a relaunch
  proves the data came from the file.
- Delete `save.json` before each case unless the case tells you to write one.

---

## Case 1 — Normal save and Continue

**Steps**

1. New Game.
2. Read the logbook to the end; pick "She was tired and seeing things." and
   then "Radio the mainland about this."
3. Press F2, then F1 (in that order).
4. Esc → Save.
5. Open `save.json`.
6. Relaunch → Continue → press F3.
7. Without closing the game: Esc → Main Menu → New Game → press F1 only, do
   **not** save → Esc → Main Menu → Continue → F3.

**Expect**

- [ ] Step 4: the button reads "Saved ✓".
- [ ] Step 5: the file has four keys — `flags`, `journal`, `scene`, `version`.
- [ ] Step 5: `"journal"` is `["entry_test_b", "entry_test_a"]`, in discovery
      order, not alphabetical.
- [ ] Step 5: `"flags"` holds `"skeptic": true` and `"trusted_edith": true`;
      `"version"` is `1`; `"scene"` is `res://scenes/game.tscn`.
- [ ] Step 6: Continue is enabled and loads the ground floor.
- [ ] Step 6: F3 prints both entries in the same order, and the same two flags.
- [ ] Step 7: F3 prints exactly what step 6 printed — both entries in the
      saved order and both flags. The load replaces what was in memory; it
      does not merge with it.

---

## Case 2 — Older v1 save with no journal data

**Steps**

1. With the game closed, write this as `save.json`:

   ```json
   {
   	"version": 1,
   	"scene": "res://scenes/game.tscn",
   	"flags": { "believer": true, "trusted_edith": false, "radioed_tom": true }
   }
   ```

2. Launch → Continue → press F3.
3. Esc → Save, then open `save.json`.
4. Stale-memory check, without closing the game: from the pause menu pick
   Main Menu → New Game → F1 → Esc → Main Menu. Overwrite `save.json` with
   the step 1 contents (step 3 rewrote it) → Continue → F3.

**Expect**

- [ ] Step 2: Continue is enabled and loads the ground floor, with no
      `GameState:` errors in the Output panel.
- [ ] Step 2: F3 prints an empty journal and all three flags, with
      `trusted_edith` still `false` (present, not missing).
- [ ] Step 3: the file now has `"journal": []` and the same three flags.
- [ ] Step 4: F3 prints an empty journal. `entry_test_a` from before the load
      is gone, and no entries were invented from the flags.

---

## Case 3 — New Game after a Continue

**Steps**

1. Produce a save with both test entries and at least one flag (Case 1,
   steps 1–4).
2. Relaunch → Continue → F3 to confirm the entries are loaded.
3. Esc → Main Menu → New Game → F3.
4. Open `save.json` without saving in the game.
5. Press F1, Esc → Save, then open `save.json` again.

**Expect**

- [ ] Step 3: F3 prints an empty journal and empty flags.
- [ ] Step 4: the file is unchanged — it still holds the old run's entries
      and flags. New Game does not touch the file.
- [ ] Step 5: the file now has `"journal": ["entry_test_a"]` and no flags
      from the old run.

---

## Case 4 — Discovering the same entry twice

**Steps**

1. New Game.
2. Press F1 three times, then F2 once, then F1 again → F3.
3. Esc → Save, then open `save.json`.
4. Relaunch → Continue → F1 → F3.
5. Esc → Save, then open `save.json`.

**Expect**

- [ ] Step 2: F3 prints `entry_test_a` once and `entry_test_b` once, with
      `entry_test_a` first.
- [ ] Step 3: `"journal"` is `["entry_test_a", "entry_test_b"]` — no
      duplicates.
- [ ] Step 4: F3 prints the same two entries; rediscovering an entry that
      came from the save adds nothing.
- [ ] Step 5: `"journal"` is unchanged from step 3.

---

## Case 5 — Malformed journal data, rest of the file fine

The file must stay valid JSON in every variant; only the `journal` value is
wrong. Run steps 2–3 once per variant.

**Steps**

1. With the game closed, write `save.json` as below, replacing `JOURNAL` with
   one variant at a time:

   ```json
   {
   	"version": 1,
   	"scene": "res://scenes/game.tscn",
   	"flags": { "skeptic": true, "radioed_tom": true },
   	"journal": JOURNAL
   }
   ```

   | Variant | `JOURNAL` |
   |---------|-----------|
   | A — not a list | `"oops"` |
   | B — null | `null` |
   | C — object | `{ "entry_test_a": true }` |
   | D — mixed list | `["entry_test_a", 7, "", null, "entry_test_a", ["x"], "entry_test_b"]` |

2. Launch → Continue → F3.
3. Esc → Save, then open `save.json`.

**Expect**

- [ ] Every variant: Continue is enabled and loads the ground floor; the game
      does not crash or stop on a script error.
- [ ] Every variant: F3 prints both flags, `skeptic` and `radioed_tom`, intact.
- [ ] Variants A, B, C: F3 prints an empty journal.
- [ ] Variant D: F3 prints `entry_test_a` then `entry_test_b` — the number,
      the empty string, the null, the nested list and the duplicate are all
      skipped.
- [ ] Step 3, every variant: the rewritten file has a clean `"journal"` list
      matching what F3 printed.

---

## Not covered by this change

These behave as they did before the branch and are not failures here:

- A save that is not valid JSON at all: Continue does nothing visible.
- A save with a `version` other than 1: it is loaded anyway.
- A crash while saving can leave a truncated `save.json`; there is no backup.

## Before calling it done

- [ ] All five cases pass.
- [ ] The debug keys are removed from `scripts/game.gd` and `git status` is
      clean.
- [ ] `python3 tests/validate_dialogue.py` still passes.
