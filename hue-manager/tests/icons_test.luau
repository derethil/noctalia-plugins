local t = require("./assert")
local icons = require("../lib/icons")

t.eq(icons.forRoom("living_room", true), "room-living", "living room archetype")
t.eq(icons.forRoom("kitchen", true), "room-kitchen", "kitchen archetype")
t.eq(icons.forRoom("kids_bedroom", true), "room-kids", "kids room archetype")
t.eq(icons.forRoom("living_room", false), "door", "room icons can be disabled")
t.eq(icons.forRoom("not_a_real_archetype", true), "door", "unknown room archetype falls back")
t.eq(icons.forRoom("", true), "door", "empty room archetype falls back")

t.eq(icons.forLight("table_shade", true), "table-shade", "table shade archetype")
t.eq(icons.forLight("ceiling_round", true), "ceiling-round", "ceiling archetype")
t.eq(icons.forLight("wall_shade", true), "wall-shade", "wall archetype")
t.eq(icons.forLight("hue_lightstrip_tv", true), "lightstrip-tv", "TV strip archetype")
t.eq(icons.forLight("table_shade", false), "bulb", "light icons can be disabled")
t.eq(icons.forLight("not_a_real_archetype", true), "bulb-classic", "unknown light archetype falls back")

t.finish("icons")
