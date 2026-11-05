# Launcher

A small app launcher for Quickshell, built from
[Tacit.Kit](https://design.tacitos.co) parts. It opens as one floating
window centred on the screen and shows at most eight apps in a single
column: big icon beside a plain name, no descriptions. With nothing typed
it shows the eight apps used most; typing narrows to the best eight
matches.

## Run

On Tacit:

```sh
qs -p app.qml
```

Elsewhere, put the kit's `qml/` folder on the import path:

```sh
QML_IMPORT_PATH=/path/to/tacit-kit/qml qs -p app.qml
```

Quickshell 0.3 or later and Qt 6.7 or later are required.

On Hyprland, bind it to a key (this is what Tacit's own launcher, fuzzel,
is replaced with here):

```lua
-- ~/.config/hypr/custom/keybinds.lua
hl.bind("CTRL + space", hl.dsp.exec_cmd("qs -n -p /path/to/launcher/app.qml"))
```

`-n` means a second Ctrl+Space while it is open does nothing, rather than
stacking another copy. A window rule gives it its size and its place:

```lua
-- ~/.config/hypr/custom/rules.lua
hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, float = true })
hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, size = { "560", "624" } })
hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, center = true })
```

## Keys and clicks

- Start typing to narrow the list; a name hit beats a word the app merely
  answers to, which beats a word in its description.
- Down hands the keyboard from the field to the list; Up on the first row
  gives it back.
- Up and Down choose, Home and End jump, Enter or a double click opens.
- Escape closes, and so does a click outside — a launcher that lingers has
  already failed.

## What is remembered

Every launch counts one use in
`~/.local/state/tacit-launcher/usage.json`, so the first eight learn the
person's habits as they go. The counts are keyed by the desktop entry id
with any `.desktop` ending removed, so the file works whether the system's
ids carry the ending or not. Delete the file to start over.

## Files

- `app.qml` — the window: the field, the eight shown, the counts, closing.
- `AppList.qml` — one column of rows, icon beside name. The kit's RowList
  of ListRows is the part for a list of things, but its rows are 44 high
  with a small kind picture; a launcher wants the icon and the name said
  loudly, so this is built from the kit's parts with the same keyboard
  manners.

Both follow the Tacit rules: every value comes from `Kit.tokens`, text is
quieted by ink and never by opacity, motion uses `Kit.ms()` so it stops
with reduced motion, and there are no dialogs.
