local types = require("./types.d.luau")
type State = types.State
type BridgeResponse = types.BridgeResponse

local M = {}

function M.create(state: State, request, publish, refresh)
	local queue = { items = {}, order = {}, inFlight = false }

	local function dispatchNext()
		if queue.inFlight then
			return
		end

		local key = table.remove(queue.order, 1)

		if key == nil then
			return
		end

		local item = queue.items[key]
		queue.items[key] = nil

		if item == nil then
			return dispatchNext()
		end

		queue.inFlight = true

		request(
			{ path = item.path, method = "PUT", body = noctalia.json.encode(item.body) },
			function(response: BridgeResponse)
				queue.inFlight = false

				if item.pendingKey ~= nil then
					state.pending[item.pendingKey] = nil
					publish()
				end

				if item.onComplete ~= nil then
					item.onComplete()
				end

				if not response.ok and state.status ~= "unauthorized" then
					noctalia.notifyError(noctalia.tr("notify.error.title"), response.error or "")
					refresh()
				end

				dispatchNext()
			end
		)

		return
	end

	return function(key: string, path: string, body, pendingKey: string?, onComplete)
		if queue.items[key] == nil then
			table.insert(queue.order, key)
		end

		queue.items[key] = { path = path, body = body, pendingKey = pendingKey, onComplete = onComplete }

		dispatchNext()
	end
end

return M
