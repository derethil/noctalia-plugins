local PICK_TIMEOUT_MS = 60000

local active = false

local function render()
  if not active and noctalia.getConfig("inactive_mode") == "hide" then
    barWidget.setVisible(false)
    return
  end

  barWidget.setVisible(true)
  barWidget.setGlyph("cast")
  barWidget.setGlyphColor(active and "on_surface" or "outline")
  barWidget.setTooltip(noctalia.tr(active and "tooltip.active" or "tooltip.inactive"))
end

local function setActive(value)
  active = value == true
  render()
end

setActive(noctalia.state.get("dynamic_target_active"))

noctalia.state.watch("dynamic_target_active", setActive)

function onClick()
  if not active then
    return
  end

  noctalia.runAsync({ "niri", "msg", "--json", "pick-window" }, function(result)
    if result.exitCode ~= 0 then
      return
    end
    local window = noctalia.json.decode(result.stdout)
    if not window or not window.id then
      return
    end
    noctalia.runAsync({
      "niri", "msg", "action", "set-dynamic-cast-window", "--id", string.format("%d", window.id),
    })
  end, PICK_TIMEOUT_MS)
end
