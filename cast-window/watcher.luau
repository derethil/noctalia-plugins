local STATE_KEY = "dynamic_target_active"

local casts = {}

local function publish()
  for _, isDynamicTarget in pairs(casts) do
    if isDynamicTarget then
      noctalia.state.set(STATE_KEY, true)
      return
    end
  end
  noctalia.state.set(STATE_KEY, false)
end

publish()

noctalia.runStream("niri msg --json event-stream", function(line)
  if not string.find(line, "Cast", 1, true) then
    return
  end

  local event = noctalia.json.decode(line)
  if not event then
    return
  end

  if event.CastsChanged then
    casts = {}
    for _, cast in ipairs(event.CastsChanged.casts) do
      casts[cast.stream_id] = cast.is_dynamic_target
    end
  elseif event.CastStartedOrChanged then
    local cast = event.CastStartedOrChanged.cast
    casts[cast.stream_id] = cast.is_dynamic_target
  elseif event.CastStopped then
    casts[event.CastStopped.stream_id] = nil
  else
    return
  end

  publish()
end)
