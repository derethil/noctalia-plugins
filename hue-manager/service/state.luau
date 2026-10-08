local types = require("./types.d.luau")
type State = types.State

local M = {}

function M.create()
	local state: State = {
		status = "connecting",
		message = "",
		bridgeIp = nil,
		savedIp = nil,
		key = nil,
		model = nil,
		pending = {},
		pendingAll = false,
		displayBrightness = {},
	}

	local function publish()
		local payload = {
			status = state.status,
			message = state.message,
			bridgeIp = state.bridgeIp,
			res = { room = {}, light = {}, grouped_light = {}, scene = {} },
			index = { roomLights = {}, lightRoom = {}, roomGroup = {}, roomScenes = {} },
			pending = state.pending,
			pendingAll = state.pendingAll,
			displayBrightness = state.displayBrightness,
		}

		if state.model ~= nil then
			payload.res = state.model.res
			payload.index = state.model.index
		end

		noctalia.state.set("model", payload)
	end

	local function rememberBrightness(target: string, id: string, brightness)
		if type(brightness) == "number" and brightness > 0 then
			state.displayBrightness[target .. ":" .. id] = brightness
		end
	end

	local function rememberResourceBrightness(resourceType: string, id: string)
		if state.model == nil then
			return
		end

		local resource = state.model.res[resourceType] and state.model.res[resourceType][id] or nil
		local brightness = resource and resource.dimming and resource.dimming.brightness or nil

		if resourceType == "light" then
			rememberBrightness("light", id, brightness)
		elseif resourceType == "grouped_light" and resource ~= nil and resource.owner ~= nil then
			rememberBrightness("room", resource.owner.rid, brightness)
		end
	end

	local function setStatus(status: string, message: string?)
		local entering = state.status ~= status
		state.status, state.message = status, message or ""

		if entering and (status == "error" or status == "unauthorized") then
			noctalia.notifyError(noctalia.tr("notify.error.title"), state.message)
		end

		publish()
	end

	return state, publish, setStatus, rememberBrightness, rememberResourceBrightness
end

return M
