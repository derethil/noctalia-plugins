local views = require("./ui/views.luau")

local open = false

local ctx = {
	model = nil,
	view = "rooms",
	filterRoomId = nil,
	expanded = {},
}

function ctx.send(cmd)
	noctalia.state.set("command", cmd)
end

function ctx.useDeviceIcons(): boolean
	return noctalia.getConfig("use_device_icons") ~= false
end

function ctx.render()
	panel.render(ui.column({ gap = 12, padding = 14, flexGrow = 1 }, {
		views.header(ctx),
		views.body(ctx),
	}))
end

function onOpen(_context)
	open = true
	ctx.model = noctalia.state.get("model")
	ctx.render()
end

function onClose()
	open = false
	-- The panel runtime outlives its surface, so reset its navigation state here.
	ctx.view = "rooms"
	ctx.filterRoomId = nil
	ctx.expanded = {}
end

noctalia.state.watch("model", function(value)
	ctx.model = value
	-- Avoid rebuilding the tree for every bridge event while the panel is closed.
	if open then
		ctx.render()
	end
end)
