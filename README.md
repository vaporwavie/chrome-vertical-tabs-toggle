# Google Chrome Vertical Tabs Toggle

This is a teeny tiny Hammerspoon script that toggles Chrome's **own** native vertical tab sidebar with a keyboard shortcut
and/or a flick of the mouse to the left screen edge. Inspired by https://github.com/avelino/tabbar-shortcut-chrome.

## How it works

It just presses the button Chrome already has: the "Collapse Tabs" / "Expand Tabs" control on the native vertical sidebar. It uses the macOS Accessibility API.

### Demo
<img width="720" height="405" alt="demo-vert" src="https://github.com/user-attachments/assets/1530a8b4-a4e7-4fe2-b138-2d93c36e6ff8" />


## Requirements

- macOS 13+
- [Hammerspoon](https://www.hammerspoon.org/) (`brew install --cask hammerspoon`)
- Chrome with native vertical tabs enabled: `chrome://flags/#vertical-tabs`

## Install

```sh

# Install hammerspoon and create a dot folder
brew install --cask hammerspoon
mkdir -p ~/.hammerspoon

# Clone this repo and copy the lua script to hammerspoon's dot folder
git clone https://github.com/vaporwavie/chrome-vertical-tabs-toggle your-dir
cp your-dir/google-chrome-vertical-tabs-toggle.lua ~/.hammerspoon/

# Upsert your init.lua so Hammerspoon knows about this script
echo 'dofile(hs.configdir .. "/google-chrome-vertical-tabs-toggle.lua")' \
  >> ~/.hammerspoon/init.lua
```

Then:

1. Grant Hammerspoon **Accessibility** permission when prompted (System Settings → Privacy & Security → Accessibility → enable Hammerspoon).
2. Click the Hammerspoon menu-bar icon → **Reload Config**.
3. You should see a "Vertical Tabs Toggle loaded" flash.

## Usage

- **Keyboard:** press **⌃Z** (Control+Z) while Chrome is focused to toggle the sidebar. On macOS, Undo is ⌘Z, so ⌃Z is free and won't clobber anything.
- **Mouse:** shove the cursor against the **left edge** of the screen.

Only fires while Chrome is the frontmost app. A watchdog re-enables the shortcut automatically if macOS ever disables the event tap.

## Customizing

Edit the `config` table at the top of `google-chrome-vertical-tabs-toggle.lua`:

| Key                | Meaning                                                        |
| ------------------ | -------------------------------------------------------------- |
| `scheme`           | `"both"`, `"keyboard"`, or `"mouse"`                           |
| `hotkeyMods` / `hotkeyKey` | The toggle shortcut (default `⌃Z`)                     |
| `edgePx`           | Pixels from the left edge that count as "at the edge"          |
| `edgeReleasePx`    | How far to move back before the edge can fire again            |
| `cooldownSeconds`  | Minimum gap between mouse-edge toggles                          |


## Troubleshooting

- **"toggle button not found":** make sure `chrome://flags/#vertical-tabs` is enabled and the vertical strip is showing at least once.
- **Nothing happens:** confirm Hammerspoon has Accessibility permission and that you reloaded the config after granting it.
