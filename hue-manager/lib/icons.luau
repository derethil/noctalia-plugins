--!strict

local M = {}

local FALLBACK = "bulb"

local ROOM_GLYPHS: { [string]: string } = {
	living_room = "sofa",
	kitchen = "tools-kitchen-2",
	dining = "tools-kitchen-3",
	bedroom = "bed",
	kids_bedroom = "bed",
	guest_room = "bed",
	bathroom = "bath",
	toilet = "toilet-paper",
	nursery = "baby-carriage",
	office = "desk",
	staircase = "stairs",
	hallway = "door",
	front_door = "door-enter",
	laundry_room = "wash-machine",
	storage = "box",
	closet = "hanger",
	garage = "car-garage",
	carport = "car",
	driveway = "car",
	gym = "barbell",
	lounge = "armchair",
	tv = "device-tv",
	computer = "device-desktop",
	recreation = "device-gamepad-2",
	man_cave = "device-gamepad-2",
	music = "headphones",
	reading = "book",
	studio = "palette",
	garden = "plant",
	terrace = "fence",
	balcony = "building-arch",
	pool = "pool",
	barbecue = "grill",
	home = "home",
	downstairs = "arrow-down",
	upstairs = "arrow-up",
	top_floor = "building",
	attic = "home-2",
	other = "door",
}

local LIGHT_GLYPHS: { [string]: string } = {
	table_shade = "lamp",
	table_wash = "lamp",
	flexible_lamp = "lamp",
	desk_lamp = "lamp",

	floor_shade = "lamp-2",
	floor_lantern = "lamp-2",
	bollard = "lamp-2",
	ground_spot = "lamp-2",
	recessed_floor = "lamp-2",
	wall_washer = "lamp-2",
	wall_lantern = "lamp-2",
	wall_shade = "lamp-2",
	wall_spot = "lamp-2",
	up_and_down = "lamp-2",
	up_and_down_down = "lamp-2",
	up_and_down_up = "lamp-2",

	christmas_tree = "christmas-tree",
	hue_lightstrip = "line",
	hue_lightstrip_tv = "device-tv",
	hue_go = "device-mobile",
	hue_bloom = "flower",
	string_light = "line-dashed",
	plug = "plug",
	vintage_candle_bulb = "flame",
	candle_bulb = "flame",
}

function M.forRoom(archetype: string?, useDeviceIcons: boolean): string
	if not useDeviceIcons then
		return FALLBACK
	end
	return ROOM_GLYPHS[archetype or ""] or FALLBACK
end

function M.forLight(archetype: string?, useDeviceIcons: boolean): string
	if not useDeviceIcons then
		return FALLBACK
	end
	return LIGHT_GLYPHS[archetype or ""] or FALLBACK
end

return M
