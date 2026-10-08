local M = {}
function M.render(ctx)
	local model = ctx.model

	if model == nil or model.status == "connecting" then
		return ui.column(
			{ gap = 10, align = "center", justify = "center", flexGrow = 1 },
			{
				ui.glyph({ name = "loader", size = 28, color = "primary" }),
				ui.label({ text = noctalia.tr("status.connecting"), fontSize = 12, textAlign = "center" }),
			}
		)
	end

	if model.status == "pairing" then
		return ui.column(
			{ gap = 14, align = "center", justify = "center", flexGrow = 1 },
			{
				ui.box({ width = 120, height = 120, radius = 60, border = "primary", borderWidth = 4 }),
				ui.label({
					text = noctalia.tr("panel.pair.hint"),
					fontSize = 13,
					fontWeight = "medium",
					textAlign = "center",
					maxWidth = 260,
				}),
			}
		)
	end

	if model.status == "unpaired" then
		return ui.column(
			{ gap = 12, align = "center", justify = "center", flexGrow = 1 },
			{
				ui.glyph({ name = "bulb-off", size = 32, color = "on_surface_variant" }),
				ui.label({ text = noctalia.tr("status.unpaired"), fontSize = 12, textAlign = "center" }),
				ui.button({
					text = noctalia.tr("panel.pair.button"),
					variant = "primary",
					onClick = function()
						ctx.send({ kind = "pair" })
					end,
				}),
			}
		)
	end

	if model.status == "ready" then
		return ui.column(
			{ gap = 10, align = "center", justify = "center", flexGrow = 1 },
			{
				ui.glyph({ name = "bulb", size = 28, color = "primary" }),
				ui.label({ text = noctalia.tr("panel.connected"), fontSize = 12, textAlign = "center" }),
			}
		)
	end

	return ui.column({ gap = 12, align = "center", justify = "center", flexGrow = 1 }, {
		ui.glyph({ name = "alert-triangle", size = 32, color = "error" }),
		ui.label({
			text = model.message ~= "" and model.message or noctalia.tr("notify.error.title"),
			fontSize = 13,
			color = "error",
			textAlign = "center",
			maxWidth = 280,
		}),
		ui.row({ gap = 8 }, {
			ui.button({
				text = noctalia.tr("panel.retry"),
				onClick = function()
					ctx.send({ kind = model.status == "unauthorized" and "pair" or "refresh" })
				end,
			}),
			ui.button({
				text = noctalia.tr("panel.open_settings"),
				variant = "ghost",
				onClick = function()
					noctalia.openSettings()
				end,
			}),
		}),
	})
end
return M
