-- Vertical Tabs Toggle for Chrome (Hammerspoon)
-- =================================================
-- Toggles Chrome's *native* vertical tab sidebar (the one behind
-- chrome://flags/#vertical-tabs) by pressing its "Collapse Tabs" /
-- "Expand Tabs" button through the macOS Accessibility API.
--
-- Why this instead of an extension: a Chrome extension can only add a
-- *second* tab UI in the side panel — it can't hide Chrome's own tab strip.
-- Driving the native sidebar gives you one vertical tab UI, no duplication.
--
-- Setup:
--   1. brew install --cask hammerspoon
--   2. Copy this file into ~/.hammerspoon/ (keep this filename; do NOT
--      overwrite an existing init.lua)
--   3. Add this line to your ~/.hammerspoon/init.lua (create it if absent):
--        dofile(hs.configdir .. "/google-chrome-vertical-tabs-toggle.lua")
--   4. Launch Hammerspoon, grant it Accessibility permission
--      (System Settings -> Privacy & Security -> Accessibility)
--   5. Click the Hammerspoon menu-bar icon -> "Reload Config"
--   6. Enable Chrome's vertical tabs at chrome://flags/#vertical-tabs

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
  -- "both" | "keyboard" | "mouse"
  scheme = "both",

  -- Keyboard trigger (fires only while Chrome is frontmost, and is swallowed
  -- so it won't reach the page). Default is Ctrl+Z: on macOS the Undo shortcut
  -- is Cmd+Z, so Ctrl+Z is effectively unused in Chrome and won't clobber
  -- anything. Change these to any mods/key you like.
  hotkeyMods = { "ctrl" },
  hotkeyKey = "z",

  -- Mouse trigger: slam the cursor into the left screen edge to toggle.
  edgePx = 2, -- how close to the left edge counts as "at the edge"
  edgeReleasePx = 60, -- must move this far back before it can fire again
  cooldownSeconds = 0.6, -- min time between mouse-edge toggles
}

local CHROME_BUNDLE = "com.google.Chrome"

-- ----------------------------------------------------------------------------
-- Core: find and press the native sidebar toggle button
-- ----------------------------------------------------------------------------

-- Depth-limited search for the "Collapse/Expand Tabs" button in Chrome's
-- accessibility tree. Matching is loose on purpose so it survives small
-- wording changes across Chrome versions.
local function findToggleButton(element, depth)
  if not element or depth > 10 then
    return nil
  end

  local role = element:attributeValue("AXRole")

  if role == "AXButton" then
    local label = (element:attributeValue("AXDescription") or "")
      .. " "
      .. (element:attributeValue("AXTitle") or "")
    if label:match("[Tt]ab") and (label:match("[Cc]ollapse") or label:match("[Ee]xpand")) then
      return element
    end
  end

  -- Never descend into the rendered web page. The toggle button lives in the
  -- browser chrome; walking page content is huge and slow, and doing it inside
  -- an event-tap callback makes macOS time the tap out (which is what made
  -- Cmd+S fall through to "Save" after the first press).
  if role == "AXWebArea" then
    return nil
  end

  local children = element:attributeValue("AXChildren")
  if children then
    for _, child in ipairs(children) do
      local found = findToggleButton(child, depth + 1)
      if found then
        return found
      end
    end
  end
  return nil
end

local function toggleSidebar()
  local chrome = hs.application.get(CHROME_BUNDLE)
  if not chrome then
    return
  end
  local axApp = hs.axuielement.applicationElement(chrome)
  if not axApp then
    return
  end

  local button = findToggleButton(axApp, 0)
  if button then
    button:performAction("AXPress")
  else
    hs.alert.show("Vertical Tabs: toggle button not found\n(enable chrome://flags/#vertical-tabs)")
  end
end

local function chromeIsFrontmost()
  local front = hs.application.frontmostApplication()
  return front ~= nil and front:bundleID() == CHROME_BUNDLE
end

-- ----------------------------------------------------------------------------
-- Trigger: keyboard
-- ----------------------------------------------------------------------------
local keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not chromeIsFrontmost() then
    return false
  end
  if hs.keycodes.map[event:getKeyCode()] ~= config.hotkeyKey then
    return false
  end
  if not event:getFlags():containExactly(config.hotkeyMods) then
    return false
  end
  -- Run the toggle *after* this callback returns. Keeping the event-tap
  -- callback itself instant is what prevents the tap from being disabled for
  -- being slow — so every Cmd+S keeps getting intercepted, not just the first.
  hs.timer.doAfter(0, toggleSidebar)
  return true -- swallow the event so it doesn't reach the page
end)

-- ----------------------------------------------------------------------------
-- Trigger: left screen edge
-- ----------------------------------------------------------------------------
local atEdge = false
local lastFire = 0
local mouseTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
  if not chromeIsFrontmost() then
    atEdge = false
    return false
  end

  local pos = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen()
  if not screen then
    return false
  end
  local left = screen:frame().x

  if pos.x <= left + config.edgePx then
    local now = hs.timer.secondsSinceEpoch()
    if not atEdge and (now - lastFire) >= config.cooldownSeconds then
      atEdge = true
      lastFire = now
      hs.timer.doAfter(0, toggleSidebar)
    end
  elseif pos.x > left + config.edgePx + config.edgeReleasePx then
    atEdge = false
  end
  return false
end)

-- ----------------------------------------------------------------------------
-- Wire up the selected scheme
-- ----------------------------------------------------------------------------
if config.scheme == "keyboard" or config.scheme == "both" then
  keyTap:start()
end
if config.scheme == "mouse" or config.scheme == "both" then
  mouseTap:start()
end

-- Watchdog: macOS will occasionally disable an event tap (e.g. if a callback
-- is ever judged slow, or under heavy input). When that happens the shortcut
-- silently stops working. This re-starts any tap that has been disabled, so it
-- self-heals within a couple of seconds instead of staying dead until reload.
local function ensureTapsEnabled()
  if (config.scheme == "keyboard" or config.scheme == "both") and not keyTap:isEnabled() then
    keyTap:start()
  end
  if (config.scheme == "mouse" or config.scheme == "both") and not mouseTap:isEnabled() then
    mouseTap:start()
  end
end
tapWatchdog = hs.timer.doEvery(2, ensureTapsEnabled) -- global keeps the timer alive

hs.alert.show("Vertical Tabs Toggle loaded (" .. config.scheme .. ", Ctrl+Z)")
