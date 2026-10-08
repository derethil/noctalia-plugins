local model = nil

local function anyLightsOn()
	for _, light in pairs((model and model.res and model.res.light) or {}) do
		if light.on and light.on.on == true then
			return true
		end
	end
	return false
end

local function render()
	local ready = model ~= nil and model.status == "ready"
	shortcut.setLabel(noctalia.tr("shortcut.hue_toggle"))
	shortcut.setIcon("bulb", "bulb-off")
	shortcut.setActive(anyLightsOn())
	shortcut.setEnabled(ready and model.pendingAll ~= true)
end

function onClick()
	if model ~= nil and model.status == "ready" and model.pendingAll ~= true then
		noctalia.state.set("command", { kind = "all_power", on = not anyLightsOn() })
	end
end

model = noctalia.state.get("model")
render()

noctalia.state.watch("model", function(value)
	model = value
	render()
end)
