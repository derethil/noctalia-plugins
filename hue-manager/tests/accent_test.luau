local t = require("./assert")
local policy = require("../lib/policy")

-- Gating
t.eq(policy.shouldSyncAccent(true, "#ff8800"), true, "enabled with a usable accent applies")
t.eq(policy.shouldSyncAccent(false, "#ff8800"), false, "disabled sync never applies")
t.eq(policy.shouldSyncAccent(true, nil), false, "nil accent never applies (no API 31)")
t.eq(policy.shouldSyncAccent(true, ""), false, "empty accent never applies")
t.eq(policy.shouldSyncAccent(true, "not-a-colour"), false, "malformed accent never applies")
t.eq(policy.shouldSyncAccent(true, "#FF8800"), true, "uppercase hex is usable")

-- Target resolution by room name. The list arrives already ordered.
local rooms = {
  { id = "c", name = "Attic", colorCapable = false },
  { id = "b", name = "Bathroom", colorCapable = true },
  { id = "a", name = "Living Room", colorCapable = true },
}

local all, unmatchedAll = policy.accentTargetRooms(rooms, {})
t.eq(#all, 2, "empty selection means every colour-capable room")
t.eq(all[1], "b", "target order follows the order given")
t.eq(all[2], "a", "target order follows the order given")
t.eq(#unmatchedAll, 0, "empty selection reports nothing unmatched")

local blank = policy.accentTargetRooms({ { id = "x", name = "", colorCapable = true } }, { "   " })
t.eq(#blank, 1, "a whitespace-only selection is ignored, so every room still syncs")

local some = policy.accentTargetRooms(rooms, { "Living Room" })
t.eq(#some, 1, "explicit selection narrows the targets")
t.eq(some[1], "a", "the selected room is the target")

local messy = policy.accentTargetRooms(rooms, { "  living room  " })
t.eq(#messy, 1, "matching is trimmed and case-insensitive")
t.eq(messy[1], "a", "messy name still resolves")

local incapable = policy.accentTargetRooms(rooms, { "Attic" })
t.eq(#incapable, 0, "selecting a room with no colour-capable lights targets nothing")

local stale, unmatchedStale = policy.accentTargetRooms(rooms, { "Study", "Bathroom" })
t.eq(#stale, 1, "a renamed room drops out but the rest still sync")
t.eq(stale[1], "b", "the surviving name still resolves")
t.eq(#unmatchedStale, 1, "the unmatched name is reported back")
t.eq(unmatchedStale[1], "Study", "the unmatched name is returned verbatim")

t.finish("accent")
