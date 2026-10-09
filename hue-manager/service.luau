local stateStore = require("./service/state.luau")
local bridgeFactory = require("./service/bridge.luau")
local pairingFactory = require("./service/pairing.luau")
local commandsFactory = require("./service/commands.luau")
local types = require("./service/types.d.luau")
type Command = types.Command

local state, publish, setStatus, rememberBrightness, rememberResourceBrightness = stateStore.create()
local bridge = bridgeFactory.create(state, publish, setStatus, rememberResourceBrightness)
local pairing = pairingFactory.create(state, publish, setStatus, bridge)
local commands = commandsFactory.create(state, publish, rememberBrightness, bridge, pairing.start)
local RESUME_GAP_SECONDS = 60
local lastUpdateAt = os.time()

noctalia.state.watch("command", function(command)
	if type(command) == "table" and command.kind ~= nil then
		commands.onCommand(command :: Command)
	end
end)

function update()
	local now = os.time()
	local resumed = now - lastUpdateAt > RESUME_GAP_SECONDS
	lastUpdateAt = now

	if pairing.update() then
		return
	end

	if resumed then
		bridge.recoverAfterResume()
		return
	end

	bridge.update()
end

noctalia.setUpdateInterval(pairing.pollInterval)

if bridge.loadSavedCredentials() or bridge.importOpenhueCredentials() then
	bridge.applyBridgeOverride()
	setStatus("connecting", noctalia.tr("status.connecting"))
	bridge.refresh()
else
	setStatus("unpaired", noctalia.tr("status.unpaired"))
end

function onConfigChanged()
	bridge.applyBridgeOverride()
	publish()
end

function onExit(_signal, _reason)
	bridge.stopStream()
end

-- Driven by the user's [hooks] colors_changed entry; refresh is also useful
-- for scripting and keeps the existing IPC interface stable.
function onIpc(event, _payload)
	if event == "sync-accent" then
		commands.syncAccent(false)
	elseif event == "refresh" then
		bridge.refresh()
	end
end
