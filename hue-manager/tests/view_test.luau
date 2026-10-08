local t = require("./assert")
local fixtures = require("./fixtures")
local hue = require("../lib/hue")
local view = require("../lib/view")

local model = hue.buildModel(fixtures.resources())

-- A room's state comes from its grouped_light, its identity from the room.
local living = view.room(model, "room-living")
t.eq(living.kind, "room", "room view kind")
t.eq(living.id, "room-living", "room view id is the room id, not the grouped_light id")
t.eq(living.name, "Living Room", "room view name")
t.eq(living.archetype, "living_room", "room view archetype")
t.eq(living.on, true, "room on comes from the grouped_light")
t.near(living.dimming.brightness, 80.0, 0.0001, "room brightness comes from the grouped_light")
t.eq(#living.lightIds, 2, "room view carries its light ids")
t.eq(#living.scenes, 2, "room view carries its scenes")
-- index.roomScenes comes out of pairs(), so with only two fixture scenes an
-- unsorted view can pass this by hash-order luck. Assert both positions.
t.eq(living.scenes[1].name, "Bright", "scenes are name-sorted")
t.eq(living.scenes[2].name, "Cozy!", "scenes are name-sorted")
t.eq(living.scenes[2].active, true, "the non-inactive scene reads active")
t.eq(living.scenes[1].active, false, "the inactive scene reads inactive")
t.eq(living.colorCapable, true, "a room is colour capable when any of its lights is")

local attic = view.room(model, "room-empty")
t.eq(attic.on, false, "an off room reads off")
t.eq(#attic.lightIds, 0, "empty room has no lights")
t.eq(#attic.scenes, 0, "empty room has no scenes")
t.eq(attic.colorCapable, false, "a room with no colour-capable lights is not colour capable")

-- Capability is presence. There are no *Capable booleans on a light view.
local lamp = view.light(model, "light-lamp")
t.eq(lamp.kind, "light", "light view kind")
t.eq(lamp.name, "Reading Lamp", "light view name")
t.near(lamp.dimming.brightness, 80.0, 0.0001, "light brightness")
t.near(lamp.dimming.min, 0.2, 0.0001, "min_dim_level surfaces as dimming.min")
t.near(lamp.color.x, 0.4584, 0.0001, "colour x")
t.eq(lamp.temperature.mirek, 368, "temperature mirek")
t.eq(lamp.temperature.valid, true, "temperature validity")
t.eq(lamp.temperature.min, 153, "mirek schema minimum surfaces as temperature.min")
t.eq(lamp.temperature.max, 500, "mirek schema maximum surfaces as temperature.max")

local plug = view.light(model, "light-plug")
t.eq(plug.on, false, "a capability-less light still reports power")
t.isNil(plug.dimming, "no dimming resource means no dimming in the view")
t.isNil(plug.color, "no color resource means no colour in the view")
t.isNil(plug.temperature, "no color_temperature resource means no temperature in the view")

local orphan = view.light(model, "light-orphan")
t.eq(orphan.name, "Hallway Strip", "the orphan light still has a view")

-- Views are computed, so they cannot drift from the store.
hue.applyEvent(model, { type = "light", id = "light-lamp", on = { on = false } })
t.eq(view.light(model, "light-lamp").on, false, "the view reflects a merged event")

t.isNil(view.light(model, "nope"), "unknown light id yields nil")
t.isNil(view.room(model, "nope"), "unknown room id yields nil")

-- fixtures.resources() must hand out fresh tables: the store keeps them by
-- reference and applyEvent merges in place, so a shared literal would let one
-- test's events corrupt the next test's model.
local a = hue.buildModel(fixtures.resources())
hue.applyEvent(a, { type = "light", id = "light-lamp", on = { on = false } })
local b = hue.buildModel(fixtures.resources())
t.eq(view.light(b, "light-lamp").on, true, "a second model is unaffected by the first's events")

-- Ordering. Not cosmetic: pairs() order is arbitrary and may differ between
-- calls, so an unsorted walk would reshuffle rows on every re-render.
local allRooms = view.rooms(model)
t.eq(#allRooms, 2, "every room is listed")
t.eq(allRooms[1].name, "Attic", "rooms are name-sorted")
t.eq(allRooms[2].name, "Living Room", "rooms are name-sorted")

local firstPass = view.rooms(model)
local secondPass = view.rooms(model)
t.eq(firstPass[1].id, secondPass[1].id, "repeated calls agree on order")
t.eq(firstPass[2].id, secondPass[2].id, "repeated calls agree on order")

-- Grouping for the lights view, including the room-less group.
local groups = view.lightGroups(model, nil)
t.eq(#groups, 3, "a group per room plus the room-less group")
t.eq(groups[1].name, "Attic", "groups follow room order")
t.eq(#groups[1].lights, 0, "a room with no lights still gets a group")
t.eq(groups[2].name, "Living Room", "second group is the next room by name")
t.eq(#groups[2].lights, 2, "room group carries its lights")
t.eq(groups[2].lights[1].name, "Counter Plug", "group lights are name-sorted")
t.eq(groups[2].lights[2].name, "Reading Lamp", "group lights are name-sorted")
t.isNil(groups[3].id, "the room-less group has no id, which is how the renderer spots it")
t.eq(#groups[3].lights, 1, "the orphan light is reachable")
t.eq(groups[3].lights[1].name, "Hallway Strip", "the orphan light is in the last group")

-- A view must not expose the store's internals.
local roomView = view.room(model, "room-living")
t.truthy(roomView.lightIds ~= model.index.roomLights["room-living"], "lightIds is a copy, not the index array")
table.remove(roomView.lightIds)
t.eq(#model.index.roomLights["room-living"], 2, "mutating the view leaves the store intact")

local filtered = view.lightGroups(model, "room-living")
t.eq(#filtered, 1, "a filter narrows to one room")
t.eq(filtered[1].name, "Living Room", "the filtered group is the requested room")

t.finish("view")
