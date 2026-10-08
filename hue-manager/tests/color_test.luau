local t = require("./assert")
local color = require("../lib/color")

-- Known Hue value: the live bridge reported a warm white at xy (0.4584, 0.4101).
local hex = color.xyToHex(0.4584, 0.4101, 1.0)
t.eq(#hex, 7, "xyToHex length")
t.eq(hex:sub(1, 1), "#", "xyToHex prefix")
t.truthy(tonumber(hex:sub(2, 3), 16) > tonumber(hex:sub(6, 7), 16), "xyToHex red exceeds blue for warm white")

-- Exact round trips. The forward and reverse matrices are inverses, so these
-- are equality assertions rather than tolerances. Blue and violet are the
-- cases that caught a hue-destroying normalizeGamut: lifting the negative
-- channel after scaling instead of before turned them white.
for _, value in ipairs({ "#ff0000", "#00ff00", "#0000ff", "#8000ff", "#ffaa00", "#ff5722", "#ffffff" }) do
  local x, y = color.hexToXy(value)
  t.eq(color.xyToHex(x, y, 1.0), value, "round trip " .. value)
end

-- A saturated blue must stay blue rather than washing out to white.
local bx, by = color.hexToXy("#0000ff")
t.near(bx, 0.1500, 0.02, "hexToXy blue x")
t.near(by, 0.0600, 0.02, "hexToXy blue y")

-- Degenerate inputs.
t.eq(color.xyToHex(0.3, 0.0, 1.0), "#000000", "y = 0 is black, not a divide by zero")
t.eq(color.xyToHex(0.3, 0.3, 0.0), "#000000", "zero brightness is black")
t.isNil(color.hexToXy("#fff"), "a short hex is rejected rather than misread")
t.isNil(color.hexToXy("nonsense"), "a non-hex string is rejected")
t.isNil(color.hexToXy(""), "an empty string is rejected")

-- Temperature. The conversion is self-inverse.
t.eq(color.mirekKelvin(500), 2000, "mirek 500 is 2000K")
t.eq(color.mirekKelvin(153), 6536, "mirek 153 is 6536K")
t.eq(color.mirekToKelvin(368), color.kelvinToMirek(368), "both aliases are the same function")
for mirek = 153, 500 do
  t.eq(color.kelvinToMirek(color.mirekToKelvin(mirek)), mirek, "mirek " .. mirek .. " round trips exactly")
end

-- Dimming. A nil brightness means not dimmable.
t.near(color.dimFactor(true, 100), 1.0, 0.0001, "dimFactor full")
t.near(color.dimFactor(true, 0), 0.4, 0.0001, "dimFactor zero brightness")
t.near(color.dimFactor(false, 100), 0.4, 0.0001, "dimFactor off")
t.near(color.dimFactor(true, nil), 1.0, 0.0001, "dimFactor non-dimmable but on")
t.near(color.dimFactor(false, nil), 0.4, 0.0001, "dimFactor non-dimmable and off")

-- Role tokens. The host parses the alpha suffix with std::from_chars and
-- rejects the token unless the suffix consumes cleanly as 0.0-1.0, so the
-- separator must be '.' and '%' is not allowed.
t.eq(color.roleAlpha("primary", 1.0), "primary/1.00", "full alpha token")
t.eq(color.roleAlpha("primary", 0.4), "primary/0.40", "floor alpha token")
t.eq(color.roleAlpha("on_surface", 0.642), "on_surface/0.64", "alpha rounds to hundredths")
t.eq(color.roleAlpha("primary", 1.9), "primary/1.00", "alpha clamps high")
t.eq(color.roleAlpha("primary", -1), "primary/0.00", "alpha clamps low")
t.eq(color.roleAlpha("primary", 0 / 0), "primary/1.00", "NaN cannot emit a token the host rejects")

local ax, ay, ab = color.averageXy({
  { x = 0.4, y = 0.4, brightness = 100 },
  { x = 0.6, y = 0.2, brightness = 50 },
})
t.near(ax, 0.5, 0.0001, "averageXy x")
t.near(ay, 0.3, 0.0001, "averageXy y")
t.near(ab, 0.75, 0.0001, "averageXy brightness normalised to 0-1")
t.isNil(color.averageXy({}), "averageXy of an empty list is nil")

t.finish("color")
