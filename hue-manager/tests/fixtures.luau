local M = {}

-- Built fresh on every call. The store keeps these tables by reference and
-- applyEvent merges into them in place, so handing out shared module-level
-- literals would let one test's events corrupt the next test's model.
function M.resources()
  return {
    room = {
      {
        id = "room-living", type = "room",
        children = {
          { rid = "dev-lamp", rtype = "device" },
          { rid = "dev-plug", rtype = "device" },
        },
        services = { { rid = "gl-living", rtype = "grouped_light" } },
        metadata = { name = "Living Room", archetype = "living_room" },
      },
      {
        id = "room-empty", type = "room",
        children = {},
        services = { { rid = "gl-empty", rtype = "grouped_light" } },
        metadata = { name = "Attic", archetype = "other" },
      },
    },

    device = {
      { id = "dev-lamp", type = "device", services = { { rid = "light-lamp", rtype = "light" } } },
      { id = "dev-plug", type = "device", services = { { rid = "light-plug", rtype = "light" } } },
      { id = "dev-orphan", type = "device", services = { { rid = "light-orphan", rtype = "light" } } },
    },

    light = {
      {
        id = "light-lamp", type = "light",
        owner = { rid = "dev-lamp", rtype = "device" },
        metadata = { name = "Reading Lamp", archetype = "table_shade" },
        on = { on = true },
        dimming = { brightness = 80.0, min_dim_level = 0.2 },
        color = { xy = { x = 0.4584, y = 0.4101 }, gamut_type = "C" },
        color_temperature = { mirek = 368, mirek_valid = true, mirek_schema = { mirek_minimum = 153, mirek_maximum = 500 } },
      },
      -- Capability-less: no dimming, no color, no color_temperature. The live
      -- bridge really does return lights shaped like this, and they are in
      -- rooms like any other light.
      {
        id = "light-plug", type = "light",
        owner = { rid = "dev-plug", rtype = "device" },
        metadata = { name = "Counter Plug", archetype = "table_shade" },
        on = { on = false },
      },
      -- Orphan: its device is in no room's children list.
      {
        id = "light-orphan", type = "light",
        owner = { rid = "dev-orphan", rtype = "device" },
        metadata = { name = "Hallway Strip", archetype = "wall_shade" },
        on = { on = true },
        dimming = { brightness = 50.0, min_dim_level = 1.0 },
      },
    },

    grouped_light = {
      { id = "gl-living", type = "grouped_light", owner = { rid = "room-living", rtype = "room" }, on = { on = true }, dimming = { brightness = 80.0 } },
      { id = "gl-empty", type = "grouped_light", owner = { rid = "room-empty", rtype = "room" }, on = { on = false }, dimming = { brightness = 0.0 } },
    },

    scene = {
      { id = "scene-cozy", type = "scene", group = { rid = "room-living", rtype = "room" }, metadata = { name = "Cozy!" }, status = { active = "static" } },
      { id = "scene-bright", type = "scene", group = { rid = "room-living", rtype = "room" }, metadata = { name = "Bright" }, status = { active = "inactive" } },
    },
  }
end

return M
