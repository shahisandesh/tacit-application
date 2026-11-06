#!/usr/bin/env python3
# Makes a Zed theme ("Tacit") from the same palette the Tacit shell generates for the
# wallpaper, with Tacit.Kit's own colour maths (Live.qml: inkFor, quieter, mix, apca).
# Rerun it after the wallpaper changes to pull the theme along with it.
#   python3 tacit_theme.py            -> ~/.config/zed/themes/tacit.json
import json
import os
import sys

STATE = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
PALETTE_PATH = os.path.join(STATE, "quickshell", "user", "generated", "colors.json")
THEME_DIR = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "zed", "themes")

# Defaults.qml: one fixed palette, used when the shell has generated none
FALLBACK = {
    "surface_container_low": "#221c1a", "surface_container_high": "#312b29",
    "on_background": "#ede8e7", "primary": "#dfc0b2", "on_primary": "#3e2418",
    "primary_container": "#57321f", "tertiary": "#a8c49a", "error": "#ffb4ab",
    "secondary": "#e6b8a2",
}


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb_to_hex(c, alpha=1.0):
    r, g, b = (max(0.0, min(1.0, v)) for v in c[:3])
    body = "%02x%02x%02x" % tuple(round(v * 255) for v in (r, g, b))
    return "#" + body + ("" if alpha >= 1.0 else "%02x" % round(alpha * 255))


def mix(c1, c2, p):
    # ColorUtils.mix: p of c1 into c2 (alpha channel too)
    a, b = c1, c2
    n = max(len(a), len(b))
    a = a + (1.0,) * (n - len(a))
    b = b + (1.0,) * (n - len(b))
    return tuple(p * x + (1 - p) * y for x, y in zip(a, b))


def lightness(c):
    return (max(c[:3]) + min(c[:3])) / 2


def apca(text, ground):
    def y(c):
        v = 0.2126729 * c[0] ** 2.4 + 0.7151522 * c[1] ** 2.4 + 0.0721750 * c[2] ** 2.4
        return v if v > 0.022 else v + (0.022 - v) ** 1.414
    yt, yb = y(text), y(ground)
    if yb > yt:
        s = (yb ** 0.56 - yt ** 0.57) * 1.14
        return 0 if s < 0.1 else (s - 0.027) * 100
    s = (yb ** 0.65 - yt ** 0.62) * 1.14
    return 0 if s > -0.1 else (s + 0.027) * 100


def ink_for(lc, ground, on_background):
    # an ink on `ground` that reads at contrast `lc`, walking from on_background
    far = (1.0, 1.0, 1.0) if lightness(ground) < 0.5 else (0.0, 0.0, 0.0)

    def at(t):
        return mix(on_background, ground, t) if t <= 1 else mix(far, on_background, t - 1)
    lo, hi = 0.0, 2.0
    for _ in range(18):
        mid = (lo + hi) / 2
        if abs(apca(at(mid), ground)) < lc:
            lo = mid
        else:
            hi = mid
    return at(hi)


def quieter(fg, bg, lc):
    lo, hi = 0.0, 1.0
    for _ in range(16):
        mid = (lo + hi) / 2
        if abs(apca(mix(fg, bg, mid), bg)) >= lc:
            hi = mid
        else:
            lo = mid
    return mix(fg, bg, hi)


def tokens(pal):
    rgb = {k: hex_to_rgb(v) for k, v in pal.items()}
    g = rgb["surface_container_low"]
    on = rgb["on_background"]
    t = {}
    t["ground"] = g
    t["ink_main"] = ink_for(92, g, on)
    t["ink_sec"] = mix(t["ink_main"], ink_for(85, g, on), 0.25)
    t["current_hover_ground"] = mix(t["ink_main"], g, 0.13)
    t["ink_meta"] = ink_for(75, t["current_hover_ground"], on)
    t["ink_faint"] = ink_for(60, g, on)
    t["hairline"] = ink_for(16, g, on)
    t["accent"] = rgb["primary"]
    t["ink_on_accent"] = rgb.get("on_primary", (0, 0, 0))
    t["risk"] = ink_for(75, g, rgb["error"])
    t["green"] = rgb.get("tertiary", t["accent"])
    t["second"] = rgb.get("secondary", t["accent"])
    t["raised"] = mix(t["ink_main"], g, 0.11)
    t["raised_hot"] = mix(t["ink_main"], g, 0.17)
    t["quiet"] = quieter(t["ink_main"], g, 38)
    t["past"] = quieter(t["ink_main"], g, 18)
    t["overlay"] = mix(g, rgb.get("primary_container", g), 0.8)
    t["overlay_lit"] = mix(t["ink_main"], t["overlay"], 0.1)
    t["container"] = rgb.get("surface_container_high", g)
    # the markdown viewer's sheet: the see-through ground with the kit's action wash of ink on it,
    # and a little of the wallpaper's glow coming through (the accent tint of the primary)
    sheet = mix(t["accent"], mix(t["ink_main"], g, 0.06), 0.04)
    t["sheet"] = sheet
    t["sheet_quiet"] = quieter(t["ink_main"], sheet, 36)
    t["sheet_past"] = quieter(t["ink_main"], sheet, 16)
    t["sheet_hair"] = ink_for(18, sheet, on)
    return t


def build(t):
    def ink(c, a=1.0):
        return rgb_to_hex(c, a)

    main, sec, meta, faint = t["ink_main"], t["ink_sec"], t["ink_meta"], t["ink_faint"]
    accent, green, risk, second = t["accent"], t["green"], t["risk"], t["second"]
    g, hair, quiet, past = t["sheet"], t["sheet_hair"], t["sheet_quiet"], t["sheet_past"]

    def wash(c, p):  # ink laid over the ground, the kit's wash style
        return ink(mix(c, g, p))

    syntax = {}

    def syn(name, color, style=None, weight=None):
        e = {"color": color}
        if style is not None:
            e["font_style"] = style
        if weight is not None:
            e["font_weight"] = weight
        cur = syntax
        parts = name.split(".")
        for p in parts[:-1]:
            cur = cur.setdefault(p, {})
        cur[parts[-1]] = e

    # the kit's syntax map, straight from markdown-viwer/MarkdownView.qml: accent for keywords,
    # strings, tags and marks; red only for numbers; comments faint; the rest quiet inks.
    syn("keyword", ink(accent))
    syn("tag", ink(accent))
    syn("title", ink(accent), None, 500)
    syn("label", ink(accent))
    syn("preproc", ink(accent))
    syn("variant", ink(accent))
    syn("punctuation.list_marker", ink(accent))
    syn("punctuation.markup", ink(accent))
    syn("string", ink(accent))
    syn("string.special", ink(accent))
    syn("string.escape", ink(accent))
    syn("constant", ink(accent))
    syn("attribute", ink(accent))
    syn("number", ink(risk))
    syn("boolean", ink(risk))
    syn("comment", ink(faint))
    syn("function", ink(main))
    syn("variable", ink(main))
    syn("text.literal", ink(main))
    syn("embedded", ink(main))
    syn("strong", ink(main), None, 600)
    syn("type", ink(sec))
    syn("constructor", ink(sec))
    syn("enum", ink(sec))
    syn("namespace", ink(sec))
    syn("property", ink(sec))
    syn("emphasis", ink(sec))
    syn("variable.special", ink(sec))
    syn("operator", ink(meta))
    syn("punctuation", ink(sec))
    syn("punctuation.bracket", ink(sec))
    syn("punctuation.delimiter", ink(meta))
    syn("punctuation.special", ink(meta))
    syn("link_text", ink(accent))
    syn("link_uri", ink(meta))
    syn("diff.plus", ink(green))
    syn("diff.minus", ink(risk))
    syn("hint", ink(meta))
    syn("predictive", ink(faint))

    return {
        "name": "Tacit",
        "appearance": "dark",
        "clamped": True,
        "style": {
            # one ground everywhere (rule 5): the see-through sheet's colour, no grey cards
            "background": ink(g),
            "surface.background": ink(g),
            "elevated_surface.background": ink(t["overlay"]),
            "border": ink(hair),
            "border.variant": ink(mix(hair, g, 0.6)),
            "border.focused": ink(accent),
            "border.selected": ink(accent),
            "border.transparent": ink(g, 0.0),
            "border.disabled": ink(mix(hair, g, 0.4)),
            "element.background": ink(t["raised"]),
            "element.hover": ink(t["raised"]),
            "element.active": ink(t["raised_hot"]),
            "element.selected": ink(t["raised_hot"]),
            "element.disabled": wash(main, 0.2),
            "drop_target.background": ink(t["raised_hot"]),
            "ghost_element.background": ink(g, 0.0),
            "ghost_element.hover": ink(t["raised"]),
            "ghost_element.active": ink(t["raised_hot"]),
            "ghost_element.selected": ink(t["raised_hot"]),
            "ghost_element.disabled": wash(main, 0.2),
            "text": ink(main),
            "text.muted": ink(meta),
            "text.placeholder": ink(faint),
            "text.disabled": ink(past),
            "text.accent": ink(main),          # the accent is a mark, never text
            "icon": ink(sec),
            "icon.muted": ink(meta),
            "icon.disabled": ink(faint),
            "icon.placeholder": ink(meta),
            "icon.accent": ink(accent),
            "status_bar.background": ink(g),           # the sheet everywhere, one ground (rule 5)
            "title_bar.background": ink(g),
            "title_bar.inactive_background": ink(g),
            "toolbar.background": ink(g),
            "tab_bar.background": ink(g),
            "tab.inactive_background": ink(mix(t["ground"], (0.0, 0.0, 0.0), 0.75)),
            "tab.active_background": ink(g),
            "search.match_background": ink(accent, 0.28),
            "search.active_match_background": ink(accent, 0.55),
            "panel.background": ink(g),
            "panel.focused_border": ink(accent),
            "pane.focused_border": ink(accent),
            "scrollbar.thumb.background": ink(main, 0.13),
            "scrollbar.thumb.hover_background": ink(main, 0.22),
            "scrollbar.thumb.border": ink(g, 0.0),
            "scrollbar.track.background": ink(g, 0.0),
            "scrollbar.track.border": ink(g, 0.0),
            "editor.foreground": ink(main),
            "editor.background": ink(g),
            "editor.gutter.background": ink(g),
            "editor.subheader.background": ink(t["overlay"]),
            "editor.active_line.background": ink(main, 0.06),   # the kit's action wash
            "editor.highlighted_line.background": ink(t["raised"]),
            "editor.line_number": ink(quiet),
            "editor.active_line_number": ink(main),
            "editor.hover_line_number": ink(sec),
            "editor.invisible": ink(hair),
            "editor.wrap_guide": ink(past),
            "editor.active_wrap_guide": ink(quiet),
            "editor.document_highlight.read_background": ink(accent, 0.12),
            "editor.document_highlight.write_background": ink(accent, 0.2),
            "terminal.background": ink(t["overlay"]),   # code sits on the kit's overlay glass
            "terminal.foreground": ink(main),
            "terminal.bright_foreground": ink(main),
            "terminal.dim_foreground": ink(faint),
            "terminal.ansi.black": ink(mix(g, (0, 0, 0), 0.7)),
            "terminal.ansi.bright_black": ink(quiet),
            "terminal.ansi.dim_black": ink(past),
            "terminal.ansi.red": ink(risk),
            "terminal.ansi.bright_red": ink(mix(risk, (1, 0.4, 0.35), 0.6)),
            "terminal.ansi.dim_red": wash(risk, 0.5),
            "terminal.ansi.green": ink(green),
            "terminal.ansi.bright_green": ink(mix(green, (0.4, 1, 0.45), 0.35)),
            "terminal.ansi.dim_green": wash(green, 0.5),
            "terminal.ansi.yellow": ink(second),
            "terminal.ansi.bright_yellow": ink(mix(second, (1, 0.9, 0.5), 0.4)),
            "terminal.ansi.dim_yellow": wash(second, 0.5),
            "terminal.ansi.blue": ink(accent),
            "terminal.ansi.bright_blue": ink(mix(accent, (0.5, 0.7, 1), 0.3)),
            "terminal.ansi.dim_blue": wash(accent, 0.5),
            "terminal.ansi.magenta": ink(second),
            "terminal.ansi.bright_magenta": ink(mix(second, (1, 0.5, 0.9), 0.3)),
            "terminal.ansi.dim_magenta": wash(second, 0.5),
            "terminal.ansi.cyan": ink(mix(green, accent, 0.5)),
            "terminal.ansi.bright_cyan": ink(mix(green, (0.4, 0.95, 0.95), 0.4)),
            "terminal.ansi.dim_cyan": wash(mix(green, accent, 0.5), 0.5),
            "terminal.ansi.white": ink(main),
            "terminal.ansi.bright_white": ink(main),
            "terminal.ansi.dim_white": ink(faint),
            "link_text.hover": ink(accent),
            "conflict": ink(second),
            "conflict.background": wash(second, 0.18),
            "conflict.border": wash(second, 0.5),
            "created": ink(green),
            "created.background": wash(green, 0.14),
            "created.border": wash(green, 0.4),
            "deleted": ink(risk),
            "deleted.background": wash(risk, 0.14),
            "deleted.border": wash(risk, 0.4),
            "error": ink(risk),
            "error.background": wash(risk, 0.14),
            "error.border": wash(risk, 0.4),
            "hidden": ink(past),
            "hidden.background": wash(main, 0.05),
            "hidden.border": wash(main, 0.12),
            "hint": ink(quiet),
            "hint.background": wash(accent, 0.1),
            "hint.border": wash(accent, 0.3),
            "ignored": ink(faint),
            "ignored.background": wash(main, 0.05),
            "ignored.border": ink(hair),
            "info": ink(accent),
            "info.background": wash(accent, 0.12),
            "info.border": wash(accent, 0.4),
            "modified": ink(second),
            "modified.background": wash(second, 0.14),
            "modified.border": wash(second, 0.4),
            "predictive": ink(faint),
            "predictive.background": wash(main, 0.06),
            "predictive.border": ink(hair),
            "renamed": ink(green),
            "renamed.background": wash(green, 0.1),
            "renamed.border": wash(green, 0.35),
            "success": ink(green),
            "success.background": wash(green, 0.14),
            "success.border": wash(green, 0.4),
            "unreachable": ink(faint),
            "unreachable.background": wash(main, 0.05),
            "unreachable.border": ink(hair),
            "warning": ink(risk),
            "warning.background": wash(risk, 0.12),
            "warning.border": wash(risk, 0.35),
            "players": [
                {"cursor": ink(c), "background": ink(c, 0.5), "selection": ink(c, 0.24)}
                for c in (accent, green, second, mix(accent, green, 0.5), risk, quiet, mix(green, g, 0.4), meta)
            ],
            "syntax": syntax,
        },
    }


def main():
    try:
        with open(PALETTE_PATH) as f:
            pal = json.load(f)
    except (OSError, ValueError):
        pal = {}
    pal = {**FALLBACK, **pal}
    theme = build(tokens(pal))
    family = {"name": "Tacit", "author": "tacit-tools", "themes": [theme]}
    os.makedirs(THEME_DIR, exist_ok=True)
    out = os.path.join(THEME_DIR, "tacit.json")
    with open(out, "w") as f:
        json.dump(family, f, indent=2)
        f.write("\n")
    print(out)


if __name__ == "__main__":
    sys.exit(main())
