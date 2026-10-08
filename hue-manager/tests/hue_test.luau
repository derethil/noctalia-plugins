local t = require("./assert")
local fixtures = require("./fixtures")
local hue = require("../lib/hue")

local model = hue.buildModel(fixtures.resources())

-- Resources are kept in bridge shape, unrenamed.
t.eq(model.res.light["light-lamp"].metadata.name, "Reading Lamp", "light stored raw")
t.near(model.res.light["light-lamp"].dimming.min_dim_level, 0.2, 0.0001, "bridge field names preserved")
t.eq(model.res.room["room-living"].metadata.archetype, "living_room", "room stored raw")
t.eq(model.res.grouped_light["gl-living"].on.on, true, "grouped_light stored raw")
t.isNil(model.res.device, "devices are consumed by the join, not retained")

-- Derived joins. There are no ordering arrays here; order is the view's job.
t.isNil(model.index.roomOrder, "the store holds no presentation ordering")
t.isNil(model.index.lightOrder, "the store holds no presentation ordering")
t.eq(model.index.roomGroup["room-living"], "gl-living", "room -> grouped_light")
t.eq(#model.index.roomLights["room-living"], 2, "room membership resolved through devices")
t.eq(model.index.roomLights["room-living"][1], "light-lamp", "membership follows the room's children order")
t.eq(model.index.lightRoom["light-plug"], "room-living", "the capability-less light is in a room, like a real plug")
t.eq(#model.index.roomLights["room-empty"], 0, "empty room keeps an empty list")
t.eq(model.index.lightRoom["light-lamp"], "room-living", "light -> room")
t.isNil(model.index.lightRoom["light-orphan"], "a light whose device is in no room has no room")
t.eq(#model.index.roomScenes["room-living"], 2, "scenes grouped by scene.group.rid")
t.eq(#(model.index.roomScenes["room-empty"] or {}), 0, "a room with no scenes gets an empty list")

-- Generic merge: a sparse resource patches in place.
t.eq(hue.applyEvent(model, { type = "light", id = "light-lamp", on = { on = false } }), "changed", "power event applies")
t.eq(model.res.light["light-lamp"].on.on, false, "power mutated")
t.near(model.res.light["light-lamp"].dimming.brightness, 80.0, 0.0001, "untouched branches survive the merge")

t.eq(hue.applyEvent(model, { type = "light", id = "light-lamp", dimming = { brightness = 42.0 } }), "changed", "dimming event applies")
t.near(model.res.light["light-lamp"].dimming.brightness, 42.0, 0.0001, "brightness mutated")
t.near(model.res.light["light-lamp"].dimming.min_dim_level, 0.2, 0.0001, "sibling key inside a merged table survives")

-- Verbatim shape of a real event captured from a bridge on 2026-10-08 while
-- setting a colour. The bridge sends the colour/temperature interaction
-- itself, so the reducer does not special-case it, and `mirek` is absent
-- because the bridge sent null, which json.decode drops.
t.eq(hue.applyEvent(model, {
  type = "light", id = "light-lamp",
  color = { xy = { x = 0.17, y = 0.7 } },
  color_temperature = { mirek_valid = false },
}), "changed", "colour event applies")
t.near(model.res.light["light-lamp"].color.xy.x, 0.17, 0.0001, "xy mutated")
t.eq(model.res.light["light-lamp"].color.gamut_type, "C", "gamut_type preserved when the event omits it")
t.eq(model.res.light["light-lamp"].color_temperature.mirek_valid, false, "bridge invalidated the temperature")
t.eq(model.res.light["light-lamp"].color_temperature.mirek, 368, "stale mirek retained so the slider keeps its position")

-- Scene siblings are deactivated by the bridge, in separate event entries.
t.eq(hue.applyEvent(model, { type = "scene", id = "scene-bright", status = { active = "static" } }), "changed", "scene activation applies")
t.eq(hue.applyEvent(model, { type = "scene", id = "scene-cozy", status = { active = "inactive" } }), "changed", "sibling deactivation applies")
t.eq(model.res.scene["scene-bright"].status.active, "static", "activated scene is static")
t.eq(model.res.scene["scene-cozy"].status.active, "inactive", "sibling is inactive")

-- Arrays replace wholesale rather than merging element-wise.
t.eq(hue.applyEvent(model, { type = "room", id = "room-living", children = {} }), "changed", "array event applies")
t.eq(#model.res.room["room-living"].children, 0, "array replaced, not merged")

-- Outcomes the caller branches on.
t.eq(hue.applyEvent(model, { type = "light", id = "light-nope", on = { on = true } }), "stale", "unknown id of a tracked type is stale")
t.eq(hue.applyEvent(model, { type = "zigbee_connectivity", id = "zb-1" }), "ignored", "untracked resource type is ignored")
t.eq(hue.applyEvent(model, { type = "light" }), "ignored", "an entry with no id is ignored")

-- SSE line parsing.
local decode = function(str)
  if str == '[{"data":[{"id":"light-lamp","type":"light"}],"type":"update"}]' then
    return { { data = { { id = "light-lamp", type = "light" } }, type = "update" } }
  end
  return nil, "bad json"
end

local parsed = hue.parseEventLines('data: [{"data":[{"id":"light-lamp","type":"light"}],"type":"update"}]', decode)
t.eq(#parsed, 1, "one event entry parsed")
t.eq(parsed[1].id, "light-lamp", "parsed entry id")
t.eq(#hue.parseEventLines(": hi", decode), 0, "keepalive comment yields nothing")
t.eq(#hue.parseEventLines("", decode), 0, "empty line yields nothing")
t.eq(#hue.parseEventLines("data: not json", decode), 0, "undecodable payload yields nothing")

t.finish("hue")
