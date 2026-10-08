local color = require("../lib/color.luau")
local view = require("../lib/view.luau")
local shared = require("./shared.luau")

local M = {}
local SLIDER_THROTTLE_MS = 150
local lastSliderSendMs, latestTemperatureValue = {}, {}

local function key(target: string, id: string): string
	return target .. ":" .. id
end

local function colorControl(hex: string)
	return ui.row({ gap = 8, align = "center" }, {
		ui.label({ text = hex, fontSize = 10, color = "on_surface_variant" }),
		ui.box({ width = 18, height = 18, radius = 9, fill = hex, border = "outline", borderWidth = 1 }),
	})
end

local function pickColor(ctx, target: string, id: string, hex: string)
	return function()
		noctalia.openColorPicker(hex, function(picked)
			if picked ~= nil then
				ctx.send({ kind = "color", target = target, id = id, hex = picked })
			end
		end)
	end
end

function M.lightActions(ctx, light)
	local actions, pending = {}, shared.isPending(ctx, light)

	if light.color ~= nil then
		local brightness = (light.dimming and light.dimming.brightness or 100) / 100
		local hex = color.xyToHex(light.color.x, light.color.y, brightness)
		local showingColor = light.temperature == nil or not light.temperature.valid

		table.insert(
			actions,
			shared.actionRow(
				ctx,
				"palette",
				noctalia.tr("row.color"),
				(light.on and showingColor) and "primary" or "on_surface",
				light,
				colorControl(hex),
				pickColor(ctx, "light", light.id, hex)
			)
		)
	end

	if light.temperature ~= nil then
		local mirek = light.temperature.mirek or light.temperature.min

		table.insert(
			actions,
			shared.actionRow(
				ctx,
				"temperature",
				noctalia.tr("row.temperature"),
				(light.on and light.temperature.valid) and "primary" or "on_surface",
				light,

				ui.slider({
					min = color.mirekToKelvin(light.temperature.max),
					max = color.mirekToKelvin(light.temperature.min),
					step = 50,
					value = color.mirekToKelvin(mirek),
					controlSize = "sm",
					width = 220,
					enabled = light.on == true and not pending,

					onChange = function(value)
						local n = tonumber(value)
						if n then
							latestTemperatureValue[light.id] = n
						end
					end,

					onDragEnd = function()
						local n = latestTemperatureValue[light.id]
						if n then
							latestTemperatureValue[light.id] = nil
							ctx.send({
								kind = "temperature",
								target = "light",
								id = light.id,
								mirek = color.kelvinToMirek(n),
							})
						end
					end,
				})
			)
		)
	end

	return actions
end

function M.roomColorAction(ctx, room)
	if not room.colorCapable then
		return nil
	end

	local entries = {}

	for _, id in ipairs(room.lightIds) do
		local light = view.light(ctx.model, id)
		if light and light.color then
			table.insert(
				entries,
				{
					x = light.color.x,
					y = light.color.y,
					brightness = (light.dimming and light.dimming.brightness) or 100,
				}
			)
		end
	end

	local x, y, brightness = color.averageXy(entries)

	if x == nil then
		return nil
	end

	local hex = color.xyToHex(x, y :: number, brightness)

	return shared.actionRow(
		ctx,
		"palette",
		noctalia.tr("row.color"),
		shared.accentRole(room),
		room,
		colorControl(hex),
		pickColor(ctx, "room", room.id, hex)
	)
end

function M.sceneAction(ctx, room)
	if #room.scenes == 0 then
		return nil
	end

	local names, selectedIndex = { noctalia.tr("row.scene.none") }, 0

	for index, scene in ipairs(room.scenes) do
		table.insert(names, scene.name)
		if scene.active then
			selectedIndex = index
		end
	end

	return shared.actionRow(
		ctx,
		"sparkles",
		noctalia.tr("row.scene"),
		shared.accentRole(room),
		room,
		ui.select({
			options = names,
			selectedIndex = selectedIndex,
			controlSize = "sm",
			width = 150,
			enabled = not shared.isPending(ctx, room),

			onChange = function(value)
				local i = tonumber(value)
				if i and i >= 1 then
					ctx.send({ kind = "scene", id = room.scenes[i].id })
				end
			end,
		})
	)
end

function M.throttledBrightness(ctx, target: string, id: string, value: number)
	local now, itemKey = noctalia.nowMs(), key(target, id)

	if (lastSliderSendMs[itemKey] or 0) + SLIDER_THROTTLE_MS > now then
		return
	end

	lastSliderSendMs[itemKey] = now
	ctx.send({ kind = "brightness", target = target, id = id, brightness = value })
end

function M.resetBrightnessThrottle(target: string, id: string)
	lastSliderSendMs[key(target, id)] = 0
end

function M.brightnessKey(target: string, id: string): string
	return key(target, id)
end

return M
