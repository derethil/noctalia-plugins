local actions = require("./actions.luau")
local entity = require("./entity.luau")
local shared = require("./shared.luau")
local view = require("../lib/view.luau")

local M = {}
function M.render(ctx)
	local rooms = view.rooms(ctx.model)

	if #rooms == 0 then
		return ui.column(
			{ justify = "center", align = "center", flexGrow = 1 },
			{ ui.label({ text = noctalia.tr("rooms.empty"), fontSize = 12, color = "on_surface_variant" }) }
		)
	end

	local cards = {}

	for _, room in ipairs(rooms) do
		local extras, colorAction, scene = {}, actions.roomColorAction(ctx, room), actions.sceneAction(ctx, room)

		if colorAction then
			table.insert(extras, colorAction)
		end

		if scene then
			table.insert(extras, scene)
		end

		table.insert(
			extras,
			shared.actionRow(
				ctx,
				"list",
				noctalia.trp("row.lights_count", #room.lightIds, { count = tostring(#room.lightIds) }),
				shared.accentRole(room),
				room,
				ui.row(
					{ width = 32, height = 32, align = "center", justify = "center" },
					{ ui.glyph({ name = "chevron-right", size = 15, color = "on_surface_variant" }) }
				),
				function()
					ctx.view = "lights"
					ctx.filterRoomId = room.id
					ctx.render()
				end
			)
		)
		table.insert(cards, entity.row(ctx, room, extras))
	end

	table.insert(
		cards,
		1,
		ui.row(
			{ key = "head-rooms", align = "center", gap = 8, minHeight = 32 },
			{ ui.label({ text = noctalia.tr("panel.view.rooms"), fontSize = 14, fontWeight = "bold", flexGrow = 1 }) }
		)
	)

	local on, total = 0, 0
	for _, light in pairs(ctx.model.res.light) do
		total += 1
		if light.on and light.on.on == true then
			on += 1
		end
	end

	return ui.scroll({ gap = 10, flexGrow = 1 }, {
		shared.section(
			"master-power",
			"",
			{
				ui.row({ key = "master-power-row", align = "center", gap = 8, minHeight = 44 }, {
					ui.label({ text = noctalia.tr("panel.title"), fontSize = 14, flexGrow = 1 }),
					ui.label({
						text = noctalia.trp("panel.lights_on", total, { on = tostring(on), total = tostring(total) }),
						fontSize = 13,
						color = "on_surface_variant",
					}),
					ui.toggle({
						checked = on > 0,
						enabled = ctx.model.pendingAll ~= true,
						onChange = function(value)
							ctx.send({ kind = "all_power", on = value == "true" })
						end,
					}),
				}),
			}
		),
		shared.section("rooms", "", cards),
	})
end

return M
