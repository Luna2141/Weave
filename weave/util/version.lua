-- weave/util/version.lua
-- Minimal dotted-version comparison, good enough for constraints like
-- ">=2.38", "=5.4.7", "<3.0". Compares purely numeric components;
-- anything non-numeric (e.g. "-2" release suffixes) is ignored for
-- comparison purposes -- fine for a "does this satisfy the constraint"
-- check, not meant to be a full semver implementation.

local function to_nums(v)
  local nums = {}
  for n in v:gmatch("%d+") do
    table.insert(nums, tonumber(n))
  end
  return nums
end

-- Returns -1, 0, or 1 (a < b, a == b, a > b)
local function compare(a, b)
  local na, nb = to_nums(a), to_nums(b)
  for i = 1, math.max(#na, #nb) do
    local x, y = na[i] or 0, nb[i] or 0
    if x < y then return -1 end
    if x > y then return 1 end
  end
  return 0
end

-- constraint examples: ">=2.38", "=5.4.7", "<3.0", or nil (always satisfied)
local function satisfies(version, constraint)
  if not constraint or constraint == "" then
    return true
  end
  local op, target = constraint:match("^(>=|<=|>|<|=)(.+)$")
  if not op then
    op, target = "=", constraint
  end

  local c = compare(version, target)
  if op == "=" then
    return c == 0
  elseif op == ">=" then
    return c >= 0
  elseif op == "<=" then
    return c <= 0
  elseif op == ">" then
    return c > 0
  elseif op == "<" then
    return c < 0
  end
  return false
end

local M = {}
M.compare = compare
M.satisfies = satisfies
return M
