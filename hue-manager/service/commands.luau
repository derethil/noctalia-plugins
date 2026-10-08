local color = require("../lib/color.luau")
local policy = require("../lib/policy.luau")
local view = require("../lib/view.luau")
local queueFactory = require("./queue.luau")
local types = require("./types.d.luau")
type State = types.State
type Command = types.Command
type HuePayload = types.HuePayload

local M = {}

function M.create(state: State, publish, rememberBrightness, bridge, startPairing)
	local enqueue = queueFactory.create(state, bridge.request, publish, bridge.refresh)

	local function pendingKey(target: string, id: string): string
		return target .. ":" .. id
	end

	local function pathOf(resourceType: string, resourceId: string): string
		return "/clip/v2/resource/" .. resourceType .. "/" .. resourceId
	end

	local function resourceTarget(target: string, id: string): (string?, string?)
		if target == "light" then
			return state.model.res.light[id] ~= nil and "light" or nil, id
		end
		if target ~= "room" then
			return nil, nil
		end
		local grouped = state.model.index.roomGroup[id]
		return grouped ~= nil and state.model.res.grouped_light[grouped] ~= nil and "grouped_light" or nil, grouped
	end

	local function predict(patch)
		require("../lib/hue.luau").applyEvent(state.model, patch)
		publish()
	end

	local function applyPower(target: string, id: string, on: boolean, onComplete)
		local resourceType, resourceId = resourceTarget(target, id)

		if resourceType == nil then
			return
		end

		local pending, body = pendingKey(target, id), { on = { on = on } }
		state.pending[pending] = true

		predict({ type = resourceType, id = resourceId, on = body.on })
		enqueue("power:" .. target .. ":" .. id, pathOf(resourceType, resourceId), body, pending, onComplete)
	end

	local function applyAllPower(on: boolean)
		local targets = {}

		for _, room in ipairs(view.rooms(state.model)) do
			if resourceTarget("room", room.id) ~= nil then
				table.insert(targets, { target = "room", id = room.id })
			end
		end

		for lightId in pairs(state.model.res.light) do
			if state.model.index.lightRoom[lightId] == nil then
				table.insert(targets, { target = "light", id = lightId })
			end
		end

		if #targets == 0 then
			return
		end

		state.pendingAll = true
		local remaining = #targets

		local function complete()
			remaining -= 1
			if remaining == 0 then
				state.pendingAll = false
				publish()
			end
		end

		for _, target in ipairs(targets) do
			applyPower(target.target, target.id, on, complete)
		end
	end

	local function applyBrightness(target: string, id: string, brightness: number)
		local resourceType, resourceId = resourceTarget(target, id)

		if resourceType == nil then
			return
		end

		local clamped, pending = math.clamp(brightness, 0, 100), pendingKey(target, id)
		state.pending[pending] = true

		rememberBrightness(target, id, clamped)
		predict({ type = resourceType, id = resourceId, dimming = { brightness = clamped } })

		enqueue(
			"brightness:" .. target .. ":" .. id,
			pathOf(resourceType, resourceId),
			{ dimming = { brightness = clamped } },
			pending
		)
	end

	local function applyTemperature(id: string, mirek: number)
		local light = view.light(state.model, id)

		if light == nil or light.temperature == nil then
			return
		end

		local clamped = math.floor(math.clamp(mirek, light.temperature.min, light.temperature.max) + 0.5)

		predict({ type = "light", id = id, color_temperature = { mirek = clamped, mirek_valid = true } })
		enqueue("temperature:light:" .. id, pathOf("light", id), { color_temperature = { mirek = clamped } })
	end

	local function applyColorToLight(id: string, x: number, y: number, turnOn: boolean)
		local patch: HuePayload =
			{ type = "light", id = id, color = { xy = { x = x, y = y } }, color_temperature = { mirek_valid = false } }

		local body: HuePayload = { color = { xy = { x = x, y = y } } }

		if turnOn then
			patch.on = { on = true }
			body.on = { on = true }
		end

		predict(patch)
		enqueue("color:light:" .. id, pathOf("light", id), body)
	end

	local function applyColor(target: string, id: string, hex: string)
		local x, y = color.hexToXy(hex)

		if x == nil then
			return
		end

		if target == "light" then
			local light = view.light(state.model, id)

			if light and light.color then
				applyColorToLight(id, x, y :: number, false)
			end

			return
		end

		local room = target == "room" and view.room(state.model, id) or nil

		if room == nil then
			return
		end

		for _, lightId in ipairs(room.lightIds) do
			local light = view.light(state.model, lightId)

			if light and light.color then
				applyColorToLight(lightId, x, y :: number, false)
			end
		end
	end

	local function applyScene(id: string)
		local scene = state.model.res.scene[id]

		if scene == nil then
			return
		end

		local roomId = scene.group and scene.group.rid or nil

		for _, sibling in ipairs((roomId and state.model.index.roomScenes[roomId]) or { id }) do
			predict({ type = "scene", id = sibling, status = { active = sibling == id and "static" or "inactive" } })
		end

		local grouped = roomId and state.model.index.roomGroup[roomId] or nil

		if grouped then
			predict({ type = "grouped_light", id = grouped, on = { on = true } })
		end

		enqueue("scene:" .. id, pathOf("scene", id), { recall = { action = "active" } })
	end

	local function syncAccent(manual: boolean)
		if state.model == nil then
			return
		end

		local accent = noctalia.getColor ~= nil and noctalia.getColor("primary") or nil

		if not policy.shouldSyncAccent(manual or noctalia.getConfig("auto_sync_accent") == true, accent) then
			return
		end

		local selected: { string } = {}
		local configuredRooms = noctalia.getConfig("sync_rooms")

		if type(configuredRooms) == "table" then
			for _, name in ipairs(configuredRooms) do
				if type(name) == "string" then
					table.insert(selected, name)
				end
			end
		end

		-- View-model construction is intentionally dynamic; retain its boundary
		-- here instead of letting an inferred nil-array leak into policy inputs.
		local rooms: { any } = view.rooms(state.model) :: any
		local targets, unmatched = policy.accentTargetRooms(rooms, selected)

		if #unmatched > 0 then
			noctalia.log(noctalia.tr("warn.sync_rooms_unmatched", { names = table.concat(unmatched, ", ") }))
		end

		local x, y = color.hexToXy(accent :: string)

		if x == nil then
			return
		end

		for _, roomId in ipairs(targets) do
			local room = view.room(state.model, roomId)

			if room then
				for _, lightId in ipairs(room.lightIds) do
					local light = view.light(state.model, lightId)

					if light and light.color then
						applyColorToLight(lightId, x, y :: number, true)
					end
				end
			end
		end

		publish()
	end

	local function onCommand(cmd: Command)
		if cmd.kind == "pair" then
			startPairing()

		elseif cmd.kind == "refresh" then
			bridge.refresh()

		elseif state.model == nil then
			return

		elseif cmd.kind == "all_power" then
			applyAllPower(cmd.on == true)

		elseif cmd.kind == "power" and type(cmd.target) == "string" and type(cmd.id) == "string" then
			applyPower(cmd.target, cmd.id, cmd.on == true)

		elseif
			cmd.kind == "brightness"
			and type(cmd.target) == "string"
			and type(cmd.id) == "string"
			and type(cmd.brightness) == "number"
		then
			applyBrightness(cmd.target, cmd.id, cmd.brightness)

		elseif cmd.kind == "temperature" and type(cmd.id) == "string" and type(cmd.mirek) == "number" then
			applyTemperature(cmd.id, cmd.mirek)

		elseif
			cmd.kind == "color"
			and type(cmd.target) == "string"
			and type(cmd.id) == "string"
			and type(cmd.hex) == "string"

		then
			applyColor(cmd.target, cmd.id, cmd.hex)

		elseif cmd.kind == "scene" and type(cmd.id) == "string" then
			applyScene(cmd.id)

		elseif cmd.kind == "sync_accent" then
			syncAccent(true)
		end
	end

	return { onCommand = onCommand, syncAccent = syncAccent }
end
return M
