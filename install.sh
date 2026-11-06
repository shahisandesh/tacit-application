#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-or-later
# Installs this repo's apps on a Tacit machine and activates them:
#   - the launcher: binds Ctrl+Space and its window rules in Hyprland's custom Lua config
#   - the markdown viewer: a .desktop entry in ~/.local/share/applications, and its window rules
#   - the Zed theme: generates ~/.config/zed/themes/tacit.json from the wallpaper's palette
# Re-running is safe: each step adds only what is missing, and the .desktop and theme are rewritten.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ZED="${XDG_CONFIG_HOME:-$HOME/.config}/zed"
changed=0

say() { printf '\033[1m==\033[0m %s\n' "$*"; }

# --- launcher: keybind and window rules -------------------------------------------------------
bind_launcher() {
    if [[ ! -d "$HYPR" ]]; then
        say "no $HYPR (dots-hyprland Lua config) — add these by hand:"
        cat <<-EOF
		    keybind = CTRL, SPACE, exec, qs -n -p $REPO/launcher/app.qml
		    windowrulev2 = float, class:(org.quickshell), title:^(Launcher)$
		    windowrulev2 = size 560 624, class:(org.quickshell), title:^(Launcher)$
		    windowrulev2 = center, class:(org.quickshell), title:^(Launcher)$
		EOF
        return
    fi
    mkdir -p "$HYPR"
    touch "$HYPR/keybinds.lua" "$HYPR/rules.lua"
    if grep -q "launcher/app.qml" "$HYPR/keybinds.lua"; then
        say "launcher keybind already in $HYPR/keybinds.lua"
    else
        cat >> "$HYPR/keybinds.lua" <<-'EOF'

		-- the launcher (tacit-tools): eight rows, centred; -n keeps a second Ctrl+Space
		-- from stacking another copy while it is open
		hl.bind("CTRL + space", hl.dsp.exec_cmd("qs -n -p __REPO__/launcher/app.qml"))
		EOF
        sed -i "s|__REPO__|$REPO|g" "$HYPR/keybinds.lua"
        say "added the launcher keybind (Ctrl+Space)"
        changed=1
    fi
    if grep -q '\^Launcher\$' "$HYPR/rules.lua"; then
        say "launcher window rules already in $HYPR/rules.lua"
    else
        cat >> "$HYPR/rules.lua" <<-'EOF'

		-- Launcher: a floating window, its own size, centred on the workspace.
		hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, float = true })
		hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, size = { "560", "624" } })
		hl.window_rule({ match = { class = "org.quickshell", title = "^Launcher$" }, center = true })
		EOF
        say "added the launcher window rules"
        changed=1
    fi
}

# --- markdown viewer: a .desktop entry so it opens from the launcher and the app list ----------
install_viewer() {
    mkdir -p "$APPS"
    cat > "$APPS/tacit-markdown-viewer.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Markdown Viewer
GenericName=Markdown reader
Comment=Read and present Markdown files in the Tacit style
Exec=qs -n -p $REPO/markdown-viwer/app.qml
Icon=text-markdown
Categories=Utility;Viewer;TextEditor;
Terminal=false
StartupNotify=false
EOF
    say "wrote $APPS/tacit-markdown-viewer.desktop"
    if [[ -d "$HYPR" ]] && ! grep -q '\^Markdown\$' "$HYPR/rules.lua" 2>/dev/null; then
        cat >> "$HYPR/rules.lua" <<-'EOF'

		-- Markdown Viewer: floating, its own size, centred.
		hl.window_rule({ match = { class = "org.quickshell", title = "^Markdown$" }, float = true })
		hl.window_rule({ match = { class = "org.quickshell", title = "^Markdown$" }, size = { "1360", "860" } })
		hl.window_rule({ match = { class = "org.quickshell", title = "^Markdown$" }, center = true })
		EOF
        say "added the markdown viewer window rules"
        changed=1
    fi
}

# --- Zed theme: generated from the wallpaper's palette ------------------------------------------
install_theme() {
    if ! command -v python3 >/dev/null; then
        say "no python3 — skipping the Zed theme"
        return
    fi
    if ! command -v zeditor >/dev/null && [[ ! -d "$ZED" ]]; then
        say "no Zed found — skipping the theme (run zed-theme/tacit_theme.py once Zed is installed)"
        return
    fi
    mkdir -p "$ZED/themes"
    python3 "$REPO/zed-theme/tacit_theme.py" >/dev/null
    say "wrote $ZED/themes/tacit.json (rerun this script after a wallpaper change)"
}

# --- go ----------------------------------------------------------------------------------------
command -v qs >/dev/null || say "quickshell (qs) is not on PATH — the apps will not start without it"

bind_launcher
install_viewer
install_theme

if [[ $changed -eq 1 ]] && command -v hyprctl >/dev/null; then
    hyprctl reload >/dev/null 2>&1 && say "Hyprland reloaded" || true
fi

say "done. Ctrl+Space opens the launcher; Markdown Viewer is in your app list; the theme is 'Tacit' in Zed."
