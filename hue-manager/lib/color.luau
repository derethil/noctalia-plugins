--!strict
local M = {}

local XYZ_FROM_RGB = {
	{ 0.4124564, 0.3575761, 0.1804375 },
	{ 0.2126729, 0.7151522, 0.0721750 },
	{ 0.0193339, 0.1191920, 0.9503041 },
}

local RGB_FROM_XYZ = {
	{ 3.2404542, -1.5371385, -0.4985314 },
	{ -0.9692660, 1.8760108, 0.0415560 },
	{ 0.0556434, -0.2040259, 1.0572252 },
}

local function gammaEncode(v: number): number
	if v <= 0.0031308 then
		return 12.92 * v
	end
	return 1.055 * v ^ (1 / 2.4) - 0.055
end

local function gammaDecode(v: number): number
	if v <= 0.04045 then
		return v / 12.92
	end
	return ((v + 0.055) / 1.055) ^ 2.4
end

local function normalizeGamut(r: number, g: number, b: number): (number, number, number)
	local minChannel = math.min(r, g, b)
	if minChannel < 0 then
		r, g, b = r - minChannel, g - minChannel, b - minChannel
	end

	local maxChannel = math.max(r, g, b)
	if maxChannel > 1 then
		r, g, b = r / maxChannel, g / maxChannel, b / maxChannel
	end

	return math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1)
end

local function channelToHex(value: number): string
	return string.format("%02x", math.floor(math.clamp(value, 0, 1) * 255 + 0.5))
end

function M.xyToHex(x: number, y: number, brightness: number?): string
	local bri = brightness or 1.0
	if y == 0 then
		return "#000000"
	end

	local bigY = bri
	local bigX = (bigY / y) * x
	local bigZ = (bigY / y) * (1.0 - x - y)

	local m = RGB_FROM_XYZ
	local r = bigX * m[1][1] + bigY * m[1][2] + bigZ * m[1][3]
	local g = bigX * m[2][1] + bigY * m[2][2] + bigZ * m[2][3]
	local b = bigX * m[3][1] + bigY * m[3][2] + bigZ * m[3][3]

	r, g, b = normalizeGamut(r, g, b)

	return "#" .. channelToHex(gammaEncode(r)) .. channelToHex(gammaEncode(g)) .. channelToHex(gammaEncode(b))
end

function M.hexToXy(hex: string): (number?, number?)
	local clean = string.gsub(hex, "^#", "")
	if #clean ~= 6 or string.match(clean, "^%x%x%x%x%x%x$") == nil then
		return nil, nil
	end

	local r = gammaDecode((tonumber(clean:sub(1, 2), 16) :: number) / 255)
	local g = gammaDecode((tonumber(clean:sub(3, 4), 16) :: number) / 255)
	local b = gammaDecode((tonumber(clean:sub(5, 6), 16) :: number) / 255)

	local m = XYZ_FROM_RGB
	local bigX = r * m[1][1] + g * m[1][2] + b * m[1][3]
	local bigY = r * m[2][1] + g * m[2][2] + b * m[2][3]
	local bigZ = r * m[3][1] + g * m[3][2] + b * m[3][3]

	local sum = bigX + bigY + bigZ
	if sum == 0 then
		return 0.0, 0.0
	end

	return bigX / sum, bigY / sum
end

function M.averageXy(entries: { { x: number, y: number, brightness: number } }): (number?, number?, number?)
	local count = #entries
	if count == 0 then
		return nil, nil, nil
	end

	local sumX, sumY, sumB = 0.0, 0.0, 0.0
	for _, entry in ipairs(entries) do
		sumX += entry.x
		sumY += entry.y
		sumB += entry.brightness
	end

	return sumX / count, sumY / count, (sumB / count) / 100
end

function M.mirekKelvin(value: number): number
	return math.floor(1000000 / value + 0.5)
end

M.mirekToKelvin = M.mirekKelvin
M.kelvinToMirek = M.mirekKelvin

function M.dimFactor(on: boolean, brightness: number?): number
	if not on then
		return 0.4
	end
	if brightness == nil then
		return 1.0
	end
	return 0.4 + (brightness / 100) * 0.6
end

function M.roleAlpha(role: string, alpha: number): string
	if alpha ~= alpha then
		alpha = 1
	end
	local hundredths = math.clamp(math.floor(alpha * 100 + 0.5), 0, 100)
	return string.format("%s/%d.%02d", role, hundredths // 100, hundredths % 100)
end

return M
