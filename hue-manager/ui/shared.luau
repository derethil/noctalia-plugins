local color = require("../lib/color.luau")

local M = {}

function M.dimmed(role: string, entity): string
	local brightness = entity.dimming ~= nil and entity.dimming.brightness or nil
	return color.roleAlpha(role, color.dimFactor(entity.on == true, brightness))
end

function M.accentRole(entity): string
	return entity.on and "primary" or "on_surface"
end

function M.isPending(ctx, entity): boolean
	return ctx.model ~= nil and ctx.model.pending ~= nil and ctx.model.pending[entity.kind .. ":" .. entity.id] == true
end

function M.actionRow(ctx, glyphName: string, label: string, accentRole: string, entity, control, onClick)
	local children = {
		ui.glyph({ name = glyphName, size = 16, color = M.dimmed(accentRole, entity) }),
		ui.label({ text = label, fontSize = 12, flexGrow = 1 }),
	}

	if control ~= nil then
		table.insert(children, control)
	end

	local handler = onClick
	if M.isPending(ctx, entity) then
		handler = nil
	end

	return ui.row({
		align = "center",
		gap = 12,
		paddingH = 14,
		paddingV = 8,
		onClick = handler,
	}, children)
end

function M.section(key: string, title: string, children)
	local content = {}

	if title ~= "" then
		table.insert(content, ui.label({ text = title, fontSize = 14, fontWeight = "bold" }))
	end

	for _, child in ipairs(children) do
		table.insert(content, child)
	end

	return ui.column({
		key = "section-layout-v2-" .. key,
		gap = 8,
		paddingH = 12,
		paddingV = 12,
		radius = 12,
		fill = "surface_variant",
		border = "outline",
		borderWidth = 1,
	}, content)
end

return M
