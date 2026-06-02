# Native Vertical Tabs Toggle (Hammerspoon)

Toggles Chrome's **own** native vertical tab sidebar with a keyboard shortcut
and/or a flick of the mouse to the left screen edge. This is a clean
reimplementation of the idea in
[Chrome-Vertical-Tab-Sidebar-Toggle](https://github.com/Ha1baraA11/Chrome-Vertical-Tab-Sidebar-Toggle).

## How it works

It adds no UI of its own. It just presses the button Chrome already has — the
"Collapse Tabs" / "Expand Tabs" control on the native vertical sidebar — via the
macOS Accessibility API. One tab UI, toggled instantly, no duplication.

## Requirements

- macOS 13+
- [Hammerspoon](https://www.hammerspoon.org/) (`brew install --cask hammerspoon`)
- Chrome with native vertical tabs enabled: `chrome://flags/#vertical-tabs`

## Install

Hammerspoon loads a single entry point, `~/.hammerspoon/init.lua`. This script
ships under its own filename so it **won't overwrite** a config you already have
— you copy it in alongside your `init.lua` and load it with one line.

```sh
brew install --cask hammerspoon
mkdir -p ~/.hammerspoon
cp google-chrome-vertical-tabs-toggle.lua ~/.hammerspoon/

# Load it from your init.lua (creates the file if you don't have one yet):
echo 'dofile(hs.configdir .. "/google-chrome-vertical-tabs-toggle.lua")' \
  >> ~/.hammerspoon/init.lua

open -a Hammerspoon
```

Then:

1. Grant Hammerspoon **Accessibility** permission when prompted
   (System Settings → Privacy & Security → Accessibility → enable Hammerspoon).
2. Click the Hammerspoon menu-bar icon → **Reload Config**.
3. You should see a "Vertical Tabs Toggle loaded" flash.

## Usage

- **Keyboard:** press **⌃Z** (Control+Z) while Chrome is focused to toggle the
  sidebar. On macOS, Undo is ⌘Z, so ⌃Z is free and won't clobber anything.
- **Mouse:** shove the cursor against the **left edge** of the screen.

Only fires while Chrome is the frontmost app. A watchdog re-enables the
shortcut automatically if macOS ever disables the event tap.

## Configuration

Edit the `config` table at the top of `google-chrome-vertical-tabs-toggle.lua`:

| Key                | Meaning                                                        |
| ------------------ | -------------------------------------------------------------- |
| `scheme`           | `"both"`, `"keyboard"`, or `"mouse"`                           |
| `hotkeyMods` / `hotkeyKey` | The toggle shortcut (default `⌃Z`)                     |
| `edgePx`           | Pixels from the left edge that count as "at the edge"          |
| `edgeReleasePx`    | How far to move back before the edge can fire again            |
| `cooldownSeconds`  | Minimum gap between mouse-edge toggles                          |

### About the shortcut choice

The reference project binds **⌘S**, which means ⌘S gets swallowed inside Chrome
and won't "Save" in web apps like Google Docs. This build defaults to **⌃Z**
instead: on macOS, Undo is ⌘Z, so plain Ctrl+Z is unused in Chrome and safe to
swallow. To use any other combo:

```lua
hotkeyMods = { "cmd", "shift" },
hotkeyKey  = "s",
```

## Troubleshooting

- **"toggle button not found":** make sure `chrome://flags/#vertical-tabs` is
  enabled and the vertical strip is showing at least once.
- **Nothing happens:** confirm Hammerspoon has Accessibility permission and that
  you reloaded the config after granting it.
