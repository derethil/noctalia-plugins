local PANEL_ID = "derethil/hue-manager:panel"

local model = nil

local function countOn()
  local on, total = 0, 0
  for _, light in pairs((model.res and model.res.light) or {}) do
    total = total + 1
    if light.on and light.on.on == true then on = on + 1 end
  end
  return on, total
end

local function render()
  barWidget.setGlyph("bulb")

  if model == nil or model.status == "connecting" then
    barWidget.setGlyphColor("outline")
    barWidget.setTooltip(noctalia.tr("widget.tooltip.connecting"))
    return
  end

  if model.status == "error" or model.status == "unauthorized" then
    barWidget.setGlyphColor("error")
    barWidget.setTooltip(noctalia.tr("widget.tooltip.error", { message = model.message or "" }))
    return
  end

  if model.status ~= "ready" then
    barWidget.setGlyphColor("outline")
    barWidget.setTooltip(noctalia.tr("widget.tooltip.unpaired"))
    return
  end

  local on, total = countOn()
  barWidget.setGlyphColor(on > 0 and "on_surface" or "outline")
  barWidget.setTooltip(noctalia.tr("widget.tooltip.ready", { on = tostring(on), total = tostring(total) }))
end

model = noctalia.state.get("model")
render()

noctalia.state.watch("model", function(value)
  model = value
  render()
end)

function onClick()
  noctalia.togglePanel(PANEL_ID)
end
