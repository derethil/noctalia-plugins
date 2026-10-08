local icons = require("../lib/icons.luau")
local actions = require("./actions.luau")
local hueIcon = require("./hue_icon.luau")
local shared = require("./shared.luau")

local M = {}
local latestSliderValue = {}

local function iconName(ctx, entity): string
	return entity.kind == "room" and icons.forRoom(entity.archetype, ctx.useDeviceIcons())
		or icons.forLight(entity.archetype, ctx.useDeviceIcons())
end

local function entityIcon(ctx, entity, color)
	if not ctx.useDeviceIcons() then
		return ui.glyph({ name = iconName(ctx, entity), size = 16, color = color })
	end
	return hueIcon.node(iconName(ctx, entity), color, 16)
end

function M.row(ctx, entity, extraActions)
	local expanded, accent, pending = ctx.expanded[entity.id] == true, shared.accentRole(entity), shared.isPending(ctx, entity)

	local function toggleExpanded()
		ctx.expanded[entity.id] = not expanded
		ctx.render()
	end

	local body = {}

	if entity.dimming ~= nil then
		local key = actions.brightnessKey(entity.kind, entity.id)

		table.insert(
			body,
			shared.actionRow(
				ctx,
				"brightness-up",
				noctalia.tr("row.brightness"),
				accent,
				entity,

				ui.slider({
					min = math.max(entity.dimming.min, 1),
					max = 100,
					step = 1,
					value = entity.dimming.brightness,
					controlSize = "sm",
					width = 220,
					enabled = entity.on == true and not pending,

					onChange = function(value)
						local n = tonumber(value)
						if n then
							latestSliderValue[key] = n
							actions.throttledBrightness(ctx, entity.kind, entity.id, n)
						end
					end,

					onDragEnd = function()
						local n = latestSliderValue[key]
						if n then
							actions.resetBrightnessThrottle(entity.kind, entity.id)
							latestSliderValue[key] = nil
							ctx.send({ kind = "brightness", target = entity.kind, id = entity.id, brightness = n })
						end
					end,
				})
			)
		)
	end

	for _, node in ipairs(extraActions or {}) do
		table.insert(body, node)
	end

	local header = {
		entityIcon(ctx, entity, shared.dimmed(accent, entity)),
		ui.label({ text = entity.name, fontSize = 14, flexGrow = 1, color = shared.dimmed("on_surface", entity) }),
	}

	if entity.dimming ~= nil then
		table.insert(
			header,
			ui.label({
				text = tostring(math.floor(entity.dimming.brightness + 0.5)) .. "%",
				width = 38,
				fontSize = 13,
				textAlign = "right",
				color = shared.dimmed("on_surface_variant", entity),
			})
		)
	end

	table.insert(
		header,
		ui.button({
			glyph = "power",
			glyphSize = 15,
			variant = entity.on and "primary" or "ghost",
			controlSize = "sm",
			enabled = not pending,
			tooltip = noctalia.tr("row.power"),
			onClick = function()
				ctx.send({ kind = "power", target = entity.kind, id = entity.id, on = not entity.on })
			end,
		})
	)

	table.insert(
		header,
		ui.button({
			glyph = expanded and "chevron-up" or "chevron-down",
			glyphSize = 15,
			variant = "ghost",
			controlSize = "sm",
			onClick = toggleExpanded,
		})
	)

	return ui.column({ key = "row-layout-v2-" .. entity.id, gap = 0, radius = 12, fill = "surface" }, {
		ui.row(
			{ align = "center", gap = 8, paddingH = 12, paddingV = 8, minHeight = 44, onClick = toggleExpanded },
			header
		),

		ui.separator({
			key = "actions-separator-" .. entity.id,
			thickness = 1,
			color = "outline/0.3",
			visible = expanded,
		}),

		ui.column({ key = "actions-" .. entity.id, gap = 0, paddingV = 4, visible = expanded }, body),
	})
end

return M
