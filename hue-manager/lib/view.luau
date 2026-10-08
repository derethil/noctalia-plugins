--!strict
local M = {}

local function dimmingOf(resource: any, displayBrightness: any): any?
	local dimming = resource.dimming
	if dimming == nil or dimming.brightness == nil then
		return nil
	end
	return { brightness = displayBrightness or dimming.brightness, min = dimming.min_dim_level or 0 }
end

function M.light(model: any, lightId: string): any
	local light = model.res.light[lightId]
	if light == nil then
		return nil
	end

	local color: any = nil
	if light.color ~= nil and light.color.xy ~= nil then
		color = { x = light.color.xy.x, y = light.color.xy.y }
	end

	local temperature: any = nil
	local ct = light.color_temperature
	if ct ~= nil then
		local schema = ct.mirek_schema
		temperature = {
			mirek = ct.mirek,
			valid = ct.mirek_valid == true,
			min = (schema ~= nil and schema.mirek_minimum) or 153,
			max = (schema ~= nil and schema.mirek_maximum) or 500,
		}
	end

	return {
		kind = "light",
		id = lightId,
		name = (light.metadata and light.metadata.name) or lightId,
		archetype = (light.metadata and light.metadata.archetype) or "",
		on = (light.on and light.on.on) == true,
		dimming = dimmingOf(light, model.displayBrightness and model.displayBrightness["light:" .. lightId]),
		color = color,
		temperature = temperature,
	}
end

local function byNameThenId(a: any, b: any): boolean
	if a.name ~= b.name then
		return a.name < b.name
	end
	return a.id < b.id
end

function M.room(model: any, roomId: string): any
	local room = model.res.room[roomId]
	if room == nil then
		return nil
	end

	local groupedLightId = model.index.roomGroup[roomId]
	local grouped: any = groupedLightId ~= nil and model.res.grouped_light[groupedLightId] or nil

	local lightIds: { any } = model.index.roomLights[roomId] or {}

	local colorCapable = false
	for _, lightId in ipairs(lightIds) do
		local light = model.res.light[lightId]
		if light ~= nil and light.color ~= nil and light.color.xy ~= nil then
			colorCapable = true
			break
		end
	end

	local scenes: { any } = {}
	for _, sceneId in ipairs(model.index.roomScenes[roomId] or {}) do
		local scene = model.res.scene[sceneId]
		if scene ~= nil then
			table.insert(scenes, {
				id = sceneId,
				name = (scene.metadata and scene.metadata.name) or sceneId,
				active = scene.status ~= nil and scene.status.active ~= nil and scene.status.active ~= "inactive",
			})
		end
	end
	table.sort(scenes, byNameThenId)

	return {
		kind = "room",
		id = roomId,
		name = (room.metadata and room.metadata.name) or roomId,
		archetype = (room.metadata and room.metadata.archetype) or "",
		on = (grouped ~= nil and grouped.on ~= nil and grouped.on.on) == true,
		dimming = grouped ~= nil
				and dimmingOf(grouped, model.displayBrightness and model.displayBrightness["room:" .. roomId])
			or nil,
		lightIds = table.clone(lightIds),
		scenes = scenes,
		colorCapable = colorCapable,
	}
end

function M.rooms(model: any): { any }
	local out: { any } = {}
	for roomId in pairs(model.res.room) do
		local room = M.room(model, roomId)
		if room ~= nil then
			table.insert(out, room)
		end
	end
	table.sort(out, byNameThenId)
	return out
end

function M.lightGroups(model: any, filterRoomId: string?): { any }
	local groups: { any } = {}

	for _, room in ipairs(M.rooms(model)) do
		if filterRoomId == nil or room.id == filterRoomId then
			local lights: { any } = {}
			for _, lightId in ipairs(model.index.roomLights[room.id] or {}) do
				local light = M.light(model, lightId)
				if light ~= nil then
					table.insert(lights, light)
				end
			end
			table.sort(lights, byNameThenId)
			table.insert(groups, { id = room.id, name = room.name, lights = lights })
		end
	end

	if filterRoomId == nil then
		local orphans: { any } = {}
		for lightId in pairs(model.res.light) do
			if model.index.lightRoom[lightId] == nil then
				local light = M.light(model, lightId)
				if light ~= nil then
					table.insert(orphans, light)
				end
			end
		end
		if #orphans > 0 then
			table.sort(orphans, byNameThenId)
			table.insert(groups, { id = nil, name = "", lights = orphans })
		end
	end

	return groups
end

return M
