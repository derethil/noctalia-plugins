local M = {}

local failures = 0
local checks = 0

function M.eq(actual, expected, label)
  checks = checks + 1
  if actual ~= expected then
    failures = failures + 1
    print(string.format("FAIL %s: expected %s, got %s", label, tostring(expected), tostring(actual)))
  end
end

function M.near(actual, expected, tolerance, label)
  checks = checks + 1
  if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
    failures = failures + 1
    print(string.format("FAIL %s: expected %s +/- %s, got %s",
      label, tostring(expected), tostring(tolerance), tostring(actual)))
  end
end

function M.isNil(actual, label)
  checks = checks + 1
  if actual ~= nil then
    failures = failures + 1
    print(string.format("FAIL %s: expected nil, got %s", label, tostring(actual)))
  end
end

function M.truthy(actual, label)
  checks = checks + 1
  if not actual then
    failures = failures + 1
    print(string.format("FAIL %s: expected truthy, got %s", label, tostring(actual)))
  end
end

function M.finish(suite)
  print(string.format("%s: %d checks, %d failures", suite, checks, failures))
  if failures > 0 then
    error(string.format("%s failed", suite), 0)
  end
end

return M
