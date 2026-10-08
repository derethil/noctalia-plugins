--!strict

local M = {}

local BACKOFF_FLOOR_MS = 1000
local BACKOFF_CEILING_MS = 60000

function M.backoffMs(attempt: number): number
	if attempt <= 1 then
		return BACKOFF_FLOOR_MS
	end
	local delay = BACKOFF_FLOOR_MS * 2 ^ (attempt - 1)
	if delay > BACKOFF_CEILING_MS then
		return BACKOFF_CEILING_MS
	end
	return delay
end

local function isHexColor(value: any): boolean
	return type(value) == "string" and string.match(value, "^#%x%x%x%x%x%x$") ~= nil
end

function M.shouldSyncAccent(enabled: boolean, currentHex: any): boolean
	return enabled == true and isHexColor(currentHex)
end

local function normalize(name: string): string
	return string.lower((string.gsub(name, "^%s*(.-)%s*$", "%1")))
end

function M.accentTargetRooms(rooms, selectedNames): ({ string }, { string })
	local wanted = {}
	local matched = {}
	local hasSelection = false

	for _, name in ipairs(selectedNames or {}) do
		if type(name) == "string" and normalize(name) ~= "" then
			wanted[normalize(name)] = name
			hasSelection = true
		end
	end

	local targets = {}

	for _, room in ipairs(rooms) do
		local key = normalize(room.name or "")
		local selected = wanted[key] ~= nil
		if selected then
			matched[key] = true
		end
		if room.colorCapable and (not hasSelection or selected) then
			table.insert(targets, room.id)
		end
	end

	local unmatched = {}
	for key, original in pairs(wanted) do
		if not matched[key] then
			table.insert(unmatched, original)
		end
	end
	table.sort(unmatched)

	return targets, unmatched
end

return M
