local header = require("./header.luau")
local lights = require("./lights.luau")
local rooms = require("./rooms.luau")
local status = require("./status.luau")

local M = {}

function M.header(ctx)
	return header.render(ctx)
end

function M.body(ctx)
	if ctx.model == nil or ctx.model.status ~= "ready" then
		return status.render(ctx)
	end
	return ctx.view == "lights" and lights.render(ctx) or rooms.render(ctx)
end

return M
