local hue = require("../lib/hue.luau")
local policy = require("../lib/policy.luau")
local types = require("./types.d.luau")
type State = types.State
type BridgeResponse = types.BridgeResponse

local M = {}
local RESOURCE_TYPES = { "room", "device", "light", "grouped_light", "scene" }

function M.create(state: State, publish, setStatus, rememberResourceBrightness)
	local fetching = false
	local stream = { handle = nil, attempt = 0, nextAttemptMs = 0, refetchPending = false, openedMs = 0 }

	local function credentialsPath(): string?
		local dir = noctalia.pluginDataDir()
		return dir ~= nil and dir .. "/credentials.json" or nil
	end

	local function saveCredentials()
		local path = credentialsPath()

		if path == nil or state.bridgeIp == nil or state.key == nil then
			return
		end

		local encoded = noctalia.json.encode({ bridge = state.bridgeIp, key = state.key })

		if encoded ~= nil then
			noctalia.writeFile(path, encoded)
		end
	end

	local function loadSavedCredentials(): boolean
		local path = credentialsPath()

		if path == nil or not noctalia.fileExists(path) then
			return false
		end

		local raw = noctalia.readFile(path)
		local decoded = raw ~= nil and noctalia.json.decode(raw) or nil

		if type(decoded) ~= "table" or type(decoded.key) ~= "string" or decoded.key == "" then
			return false
		end

		state.savedIp = type(decoded.bridge) == "string" and decoded.bridge or nil
		state.bridgeIp, state.key = state.savedIp, decoded.key

		return true
	end

	local function importOpenhueCredentials(): boolean
		local path = noctalia.expandPath("~/.config/openhue/config.yaml")

		if not noctalia.fileExists(path) then
			return false
		end

		local raw = noctalia.readFile(path)

		if raw == nil then
			return false
		end

		local bridge = string.match(raw, "bridge:%s*([^\r\n]+)")
		local key = string.match(raw, "key:%s*([^\r\n]+)")

		if bridge == nil or key == nil then
			return false
		end

		state.savedIp, state.key = noctalia.string.trim(bridge), noctalia.string.trim(key)
		state.bridgeIp = state.savedIp

		if state.savedIp == "" or state.key == "" then
			state.savedIp, state.bridgeIp, state.key = nil, nil, nil
			return false
		end

		saveCredentials()
		noctalia.log("imported bridge credentials from openhue config")
		return true
	end

	local function applyBridgeOverride()
		local override = noctalia.getConfig("bridge_ip")

		state.bridgeIp = type(override) == "string"
				and noctalia.string.trim(override) ~= ""
				and noctalia.string.trim(override)
			or state.savedIp
	end

	local function request(options: types.RequestOptions, onDone: (BridgeResponse) -> ())
		if state.bridgeIp == nil or state.key == nil then
			onDone({ ok = false, status = 0, body = "" })
			return
		end

		local headers = { "hue-application-key: " .. state.key }

		if options.body ~= nil then
			table.insert(headers, "Content-Type: application/json")
		end

		local accepted = noctalia.http({
			url = "https://" .. state.bridgeIp .. options.path,
			method = options.method or "GET",
			body = options.body,
			headers = headers,
			allow_insecure_tls = true,
		}, function(response)
			if response.status == 401 or response.status == 403 then
				setStatus("unauthorized", noctalia.tr("status.unauthorized"))
				onDone({ ok = false, status = response.status, body = response.body })
				return
			end

			local decoded = noctalia.json.decode(response.body or "")
			local errorText = nil

			if type(decoded) == "table" and type(decoded.errors) == "table" and decoded.errors[1] ~= nil then
				errorText = decoded.errors[1].description or "rejected"
			elseif not response.ok or response.status < 200 or response.status >= 300 then
				errorText = noctalia.tr("error.request_failed", { status = tostring(response.status) })
			end

			onDone({
				ok = errorText == nil,
				status = response.status,
				body = response.body,
				decoded = decoded,
				error = errorText,
			})
		end)

		if not accepted then
			onDone({ ok = false, status = 0, body = "" })
		end
	end

	local refresh

	local function stopStream()
		if stream.handle ~= nil then
			stream.handle.stop()
			stream.handle = nil
		end
	end

	local function connectStream()
		if stream.handle ~= nil or state.bridgeIp == nil or state.key == nil then
			return
		end

		stream.openedMs = noctalia.nowMs()

		stream.handle = noctalia.httpStream({
			url = "https://" .. state.bridgeIp .. "/eventstream/clip/v2",
			headers = { "hue-application-key: " .. state.key, "Accept: text/event-stream" },
			allow_insecure_tls = true,
		}, function(line)
			local entries = hue.parseEventLines(line, noctalia.json.decode)
			if #entries == 0 or state.model == nil then
				return
			end

			local changed, needsRefetch = false, false

			for _, entry in ipairs(entries) do
				local outcome = hue.applyEvent(state.model, entry)

				if outcome == "changed" then
					rememberResourceBrightness(entry.type, entry.id)
					changed = true
				elseif outcome == "stale" then
					needsRefetch = true
				end
			end

			if changed then
				publish()
			end

			if needsRefetch then
				refresh()
			end
		end, function(result)
			stream.handle = nil
			stream.attempt = noctalia.nowMs() - stream.openedMs > 30000 and 1 or stream.attempt + 1
			stream.nextAttemptMs = noctalia.nowMs() + policy.backoffMs(stream.attempt)
			stream.refetchPending = true

			if result.status == 401 or result.status == 403 then
				setStatus("unauthorized", noctalia.tr("status.unauthorized"))
			end
		end)

		if stream.handle == nil then
			stream.attempt += 1
			stream.nextAttemptMs = noctalia.nowMs() + policy.backoffMs(stream.attempt)
		end
	end

	refresh = function()
		if fetching then
			return
		end

		if state.bridgeIp == nil or state.key == nil then
			setStatus("unpaired", noctalia.tr("status.unpaired"))
			return
		end

		fetching = true
		local resources, remaining, failed = {}, #RESOURCE_TYPES, false

		for _, resourceType in ipairs(RESOURCE_TYPES) do
			request({ path = "/clip/v2/resource/" .. resourceType }, function(response)
				if not failed then
					if not response.ok then
						failed, fetching = true, false
						if state.status ~= "unauthorized" then
							setStatus(
								"error",
								response.error
									or noctalia.tr("error.request_failed", { status = tostring(response.status) })
							)
						end
						return
					end

					if type(response.decoded) ~= "table" or type(response.decoded.data) ~= "table" then
						failed, fetching = true, false
						setStatus("error", noctalia.tr("error.request_failed", { status = "malformed" }))
						return
					end

					resources[resourceType] = response.decoded.data

				end

				remaining -= 1

				if remaining > 0 or failed then
					return
				end

				fetching = false
				state.model = hue.buildModel(resources)

				for id in pairs(state.model.res.light) do
					rememberResourceBrightness("light", id)
				end

				for id in pairs(state.model.res.grouped_light) do
					rememberResourceBrightness("grouped_light", id)
				end

				setStatus("ready", "")
				connectStream()
			end)
		end
	end

	local function update()
		if state.status == "unauthorized" or state.status == "unpaired" then
			return
		end

		if stream.handle == nil and noctalia.nowMs() >= stream.nextAttemptMs then
			if stream.refetchPending then
				stream.refetchPending = false
				refresh()
			end

			connectStream()
		end
	end

	return {
		applyBridgeOverride = applyBridgeOverride,
		connectStream = connectStream,
		importOpenhueCredentials = importOpenhueCredentials,
		loadSavedCredentials = loadSavedCredentials,
		refresh = refresh,
		request = request,
		saveCredentials = saveCredentials,
		stopStream = stopStream,
		update = update,
	}
end

return M
