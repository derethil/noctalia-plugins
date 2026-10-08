local M = {}

function M.create(state, publish, setStatus, bridge)
	local pair = { active = false, startedMs = 0, nextPollMs = 0, ip = nil }
	local POLL_MS, TIMEOUT_MS = 2000, 120000
	local discoverViaBroker

	local function finish(ip: string, key: string)
		pair.active = false
		state.savedIp, state.bridgeIp, state.key = ip, ip, key
		bridge.saveCredentials()
		noctalia.notify(noctalia.tr("notify.paired.title"), noctalia.tr("notify.paired.body", { ip = ip }))
		setStatus("connecting", noctalia.tr("status.connecting"))
		bridge.refresh()
	end

	local function poll()
		if not pair.active or pair.ip == nil then
			return
		end

		if noctalia.nowMs() - pair.startedMs > TIMEOUT_MS then
			pair.active = false
			setStatus("error", noctalia.tr("error.pairing_timeout"))
			return
		end

		pair.nextPollMs = noctalia.nowMs() + POLL_MS

		local body = noctalia.json.encode({
			devicetype = "noctalia-hue-manager#" .. (noctalia.getenv("HOSTNAME") or "noctalia"),
			generateclientkey = true,
		})

		local accepted = noctalia.http({
			url = "https://" .. pair.ip .. "/api",
			method = "POST",
			body = body,
			headers = { "Content-Type: application/json" },
			allow_insecure_tls = true,
		}, function(response)
			if not pair.active then
				return
			end

			local decoded = noctalia.json.decode(response.body or "")
			local success = type(decoded) == "table" and decoded[1] and decoded[1].success or nil

			if success ~= nil and type(success.username) == "string" and success.username ~= "" then
				finish(pair.ip :: string, success.username)
			end
		end)

		if not accepted then
			pair.nextPollMs = noctalia.nowMs() + POLL_MS
		end
	end

	local function discoverViaMdns(): boolean
		if not noctalia.commandExists("avahi-browse") then
			return false
		end

		return noctalia.runAsync({ "avahi-browse", "--resolve", "--terminate", "_hue._tcp" }, function(result)
			if not pair.active then
				return
			end

			local ip = string.match(result.stdout or "", "address = %[(%d+%.%d+%.%d+%.%d+)%]")

			if ip == nil then
				discoverViaBroker()
				return
			end

			pair.ip, state.bridgeIp = ip, ip
			poll()
		end)
	end

	discoverViaBroker = function()
		local accepted = noctalia.http({ url = "https://discovery.meethue.com/" }, function(response)
			if not pair.active then
				return
			end

			if not response.ok then
				pair.active = false
				setStatus("error", noctalia.tr("error.discovery_failed"))
				return
			end

			local decoded = noctalia.json.decode(response.body or "")

			if type(decoded) ~= "table" or decoded[1] == nil or type(decoded[1].internalipaddress) ~= "string" then
				pair.active = false
				setStatus("error", noctalia.tr("error.no_bridge_found"))
				return
			end

			pair.ip, state.bridgeIp = decoded[1].internalipaddress, decoded[1].internalipaddress
			poll()
		end)

		if not accepted then
			pair.active = false
			setStatus("error", noctalia.tr("error.discovery_failed"))
		end
	end

	local function start()
		bridge.applyBridgeOverride()
		pair.active, pair.startedMs, pair.nextPollMs, pair.ip = true, noctalia.nowMs(), 0, state.bridgeIp
		setStatus("pairing", noctalia.tr("status.pairing"))

		if pair.ip ~= nil then
			poll()
			return
		end

		if not discoverViaMdns() then
			discoverViaBroker()
		end
	end

	local function update(): boolean
		if not pair.active then
			return false
		end

		if noctalia.nowMs() >= pair.nextPollMs then
			poll()
		end

		return true
	end

	return { start = start, update = update, pollInterval = POLL_MS }
end

return M
