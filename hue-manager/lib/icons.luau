--!strict

local M = {}

local ROOM_FALLBACK = "door"
local LIGHT_FALLBACK = "bulb-classic"

local ROOM_ICONS: { [string]: string } = {
	living_room = "room-living",
	kitchen = "room-kitchen",
	dining = "room-dining",
	bedroom = "room-bedroom",
	kids_bedroom = "room-kids",
	guest_room = "room-guestroom",
	bathroom = "room-bathroom",
	toilet = "room-toilet",
	nursery = "room-nursery",
	office = "room-office",
	staircase = "room-stairs",
	hallway = "room-hallway",
	front_door = "room-front-door",
	laundry_room = "room-laundry",
	storage = "room-storage",
	closet = "room-closet",
	garage = "room-garage",
	carport = "room-carport",
	driveway = "room-driveway",
	gym = "room-gym",
	lounge = "room-lounge",
	tv = "room-recreation",
	computer = "room-computer",
	recreation = "room-recreation",
	man_cave = "room-games",
	music = "room-recreation",
	reading = "room-other",
	studio = "room-studio",
	garden = "room-outdoors",
	terrace = "room-terrace",
	balcony = "room-balcony",
	pool = "room-pool",
	barbecue = "room-bbq",
	home = "home",
	downstairs = "downstairs",
	upstairs = "upstairs",
	top_floor = "upstairs",
	attic = "room-attic",
	other = "room-other",
}

local LIGHT_ICONS: { [string]: string } = {
	table_shade = "table-shade",
	table_wash = "table-wash",
	flexible_lamp = "desk-lamp",
	desk_lamp = "desk-lamp",
	floor_shade = "floor-shade",
	floor_lantern = "floor-lantern",
	bollard = "bollard",
	ground_spot = "floor-spot",
	recessed_floor = "recessed-floor",
	wall_washer = "wall-spot",
	wall_lantern = "wall-lantern",
	wall_shade = "wall-shade",
	wall_spot = "wall-spot",
	up_and_down = "wall-spot",
	up_and_down_down = "wall-spot",
	up_and_down_up = "wall-spot",
	ceiling_round = "ceiling-round",
	ceiling_square = "ceiling-square",
	pendant_round = "pendant-round",
	pendant_long = "pendant-long",
	recessed_ceiling = "recessed-ceiling",
	christmas_tree = "bulb-sultan",
	hue_lightstrip = "lightstrip",
	hue_lightstrip_tv = "lightstrip-tv",
	hue_go = "go",
	hue_bloom = "bloom",
	string_light = "lightstrip",
	plug = "plug",
	vintage_candle_bulb = "bulb-filament",
	candle_bulb = "bulb-candle",
}

function M.forRoom(archetype: string?, useDeviceIcons: boolean): string
	if not useDeviceIcons then return ROOM_FALLBACK end
	return ROOM_ICONS[archetype or ""] or ROOM_FALLBACK
end

function M.forLight(archetype: string?, useDeviceIcons: boolean): string
	if not useDeviceIcons then return "bulb" end
	return LIGHT_ICONS[archetype or ""] or LIGHT_FALLBACK
end

return M
