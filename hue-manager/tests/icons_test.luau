local t = require("./assert")
local icons = require("../lib/icons")

t.eq(icons.forRoom("living_room", true), "sofa", "living room archetype")
t.eq(icons.forRoom("kitchen", true), "tools-kitchen-2", "kitchen archetype")
t.eq(icons.forRoom("bedroom", true), "bed", "bedroom archetype")
t.eq(icons.forRoom("kids_bedroom", true), "bed", "kids bedroom shares the bed glyph")
t.eq(icons.forRoom("living_room", false), "bulb", "device icons off falls back for rooms")
t.eq(icons.forRoom("not_a_real_archetype", true), "bulb", "unknown room archetype falls back")
t.eq(icons.forRoom("", true), "bulb", "empty room archetype falls back")

t.eq(icons.forLight("table_shade", true), "lamp", "table shade archetype")
t.eq(icons.forLight("ceiling_round", true), "bulb", "ceiling archetypes fall through to the bulb fallback")
t.eq(icons.forLight("wall_shade", true), "lamp-2", "wall archetype")
t.eq(icons.forLight("table_shade", false), "bulb", "device icons off falls back for lights")
t.eq(icons.forLight("not_a_real_archetype", true), "bulb", "unknown light archetype falls back")

t.finish("icons")
