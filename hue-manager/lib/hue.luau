--!strict
local M = {}

local TRACKED: { [string]: boolean } = { room = true, light = true, grouped_light = true, scene = true }

local function serviceOfType(entry: any, rtype: string): string?
	for _, service in ipairs(entry.services or {}) do
		if service.rtype == rtype then
			return service.rid
		end
	end
	return nil
end

local function byId(list: any): { [string]: any }
	local out: { [string]: any } = {}
	if type(list) ~= "table" then
		return out
	end
	for _, item in ipairs(list) do
		if item.id ~= nil then
			out[item.id] = item
		end
	end
	return out
end

function M.buildModel(resources: { [string]: any }?): any
	local input: { [string]: any } = resources or {}

	local res: { [string]: { [string]: any } } = {
		room = byId(input.room),
		light = byId(input.light),
		grouped_light = byId(input.grouped_light),
		scene = byId(input.scene),
	}

	local index: any = {
		roomLights = {},
		lightRoom = {},
		roomGroup = {},
		roomScenes = {},
	}

	local deviceToLight: { [string]: string } = {}
	for _, device in ipairs(input.device or {}) do
		local lightId = serviceOfType(device, "light")
		if device.id ~= nil and lightId ~= nil then
			deviceToLight[device.id] = lightId
		end
	end

	for roomId, room in pairs(res.room) do
		index.roomLights[roomId] = {}
		index.roomScenes[roomId] = {}

		local groupedLightId = serviceOfType(room, "grouped_light")
		if groupedLightId ~= nil then
			index.roomGroup[roomId] = groupedLightId
		end

		for _, child in ipairs(room.children or {}) do
			if child.rtype == "device" then
				local lightId = deviceToLight[child.rid]
				if lightId ~= nil and res.light[lightId] ~= nil then
					table.insert(index.roomLights[roomId], lightId)
					index.lightRoom[lightId] = roomId
				end
			end
		end
	end

	for sceneId, scene in pairs(res.scene) do
		local roomId = scene.group ~= nil and scene.group.rtype == "room" and scene.group.rid or nil
		if roomId ~= nil and index.roomScenes[roomId] ~= nil then
			table.insert(index.roomScenes[roomId], sceneId)
		end
	end

	return { res = res, index = index }
end

local function merge(target: any, patch: any)
	for key, value in pairs(patch) do
		local existing = target[key]
		if type(value) == "table" and type(existing) == "table" and value[1] == nil and existing[1] == nil then
			merge(existing, value)
		else
			target[key] = value
		end
	end
end

function M.applyEvent(model: any, data: any): string
	if type(data) ~= "table" or data.id == nil or not TRACKED[data.type] then
		return "ignored"
	end

	local stored = model.res[data.type][data.id]
	if stored == nil then
		return "stale"
	end

	merge(stored, data)
	return "changed"
end

function M.parseEventLines(line: string, decode: (string) -> any): { any }
	local out: { any } = {}

	if line == nil or line == "" then
		return out
	end

	local payload = string.match(line, "^data:%s*(.+)$")
	if payload == nil then
		return out
	end

	local decoded = decode(payload)
	if type(decoded) ~= "table" then
		return out
	end

	for _, event in ipairs(decoded) do
		for _, entry in ipairs(event.data or {}) do
			table.insert(out, entry)
		end
	end

	return out
end

return M
