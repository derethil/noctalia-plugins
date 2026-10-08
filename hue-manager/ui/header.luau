local M = {}
function M.render(ctx)
	local model, connected = ctx.model, ctx.model ~= nil and ctx.model.status == "ready"
	local glyph, color, tooltip = "loader", "primary", noctalia.tr("status.connecting")

	if connected then
		glyph, tooltip = "plug-connected", noctalia.tr("panel.connected")
	elseif model and model.status == "pairing" then
		tooltip = noctalia.tr("status.pairing")
	elseif model and model.status == "unpaired" then
		glyph, color, tooltip = "plug-off", "error", noctalia.tr("status.unpaired")
	elseif model and (model.status == "error" or model.status == "unauthorized") then
		glyph, color, tooltip =
			"plug-off", "error", model.message ~= "" and model.message or noctalia.tr("status.unauthorized")
	end

	local controls = {}

	if connected then
		table.insert(
			controls,
			ui.button({
				glyph = "refresh",
				glyphSize = 14,
				variant = "default",
				controlSize = "sm",
				tooltip = noctalia.tr("panel.sync_now"),
				onClick = function()
					ctx.send({ kind = "sync_accent" })
				end,
			})
		)
	end

	table.insert(
		controls,
		ui.button({
			glyph = "x",
			glyphSize = 14,
			variant = "default",
			controlSize = "sm",
			tooltip = noctalia.tr("panel.close"),
			onClick = function()
				panel.close()
			end,
		})
	)

	return ui.row({ align = "center", gap = 6 }, {
		ui.row({ align = "center", gap = 6, flexGrow = 1 }, {
			ui.label({ text = noctalia.tr("panel.title"), fontSize = 17, fontWeight = "bold", color = "primary" }),
			ui.row({ align = "center", tooltip = tooltip }, { ui.glyph({ name = glyph, size = 16, color = color }) }),
		}),

		ui.row({ gap = 4, align = "center" }, controls),
	})
end

return M
