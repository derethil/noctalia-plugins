local M = {}
local written = {}

local function sourcePath(name)
	return "assets/hue-icons/" .. name .. ".svg"
end

local function colorParts(color)
	local role, whole, fraction = string.match(color, "^([^/]+)/(%d+)%.(%d+)$")
	if role and whole and fraction then return role, tonumber(whole .. "." .. fraction) or 1 end
	return color, 1
end

function M.node(name, color, size)
	local role, opacity = colorParts(color)
	local hex = noctalia.getColor(role)
	local dataDir = noctalia.pluginDataDir()
	if not hex or not dataDir then
		return ui.image({ path = sourcePath(name), width = size, height = size, fit = "contain" })
	end

	local cacheDir = dataDir .. "/hue-icons"
	local path = string.format("%s/%s-%s-%.2f.svg", cacheDir, name, string.gsub(hex, "#", ""), opacity)
	if not written[path] then
		local source = noctalia.readFile(sourcePath(name))
		if source then
			noctalia.mkdirAll(cacheDir)
			local svg = string.gsub(source, 'fill="#44739e"', string.format('fill="%s" opacity="%.2f"', hex, opacity), 1)
			local ok = noctalia.writeFile(path, svg)
			if ok then written[path] = true end
		end
	end

	return ui.image({ path = written[path] and path or sourcePath(name), width = size, height = size, fit = "contain" })
end

return M
