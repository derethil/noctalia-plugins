local actions = require("./actions.luau")
local entity = require("./entity.luau")
local shared = require("./shared.luau")
local view = require("../lib/view.luau")

local M = {}
function M.render(ctx)
	local groups = view.lightGroups(ctx.model, ctx.filterRoomId)

	if #groups == 0 then
		return ui.column(
			{ justify = "center", align = "center", flexGrow = 1 },
			{ ui.label({ text = noctalia.tr("lights.empty"), fontSize = 12, color = "on_surface_variant" }) }
		)
	end

	local sections = {}

	for _, group in ipairs(groups) do
		local id, heading = group.id or "unassigned", group.id == nil and noctalia.tr("lights.unassigned") or group.name
		local headingChildren = { ui.label({ text = heading, fontSize = 14, fontWeight = "bold", flexGrow = 1 }) }

		if ctx.filterRoomId ~= nil then
			table.insert(
				headingChildren,
				ui.button({
					glyph = "arrow-left",
					glyphSize = 15,
					variant = "ghost",
					controlSize = "sm",
					tooltip = noctalia.tr("lights.back"),
					onClick = function()
						ctx.filterRoomId = nil
						ctx.view = "rooms"
						ctx.render()
					end,
				})
			)
		end

		local children = { ui.row({ key = "head-" .. id, align = "center", gap = 8, minHeight = 32 }, headingChildren) }

		for _, light in ipairs(group.lights) do
			table.insert(children, entity.row(ctx, light, actions.lightActions(ctx, light)))
		end

		table.insert(sections, shared.section(id, "", children))
	end

	return ui.scroll({ gap = 10, flexGrow = 1 }, sections)
end

return M
