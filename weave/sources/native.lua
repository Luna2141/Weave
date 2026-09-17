-- weave/sources/native.lua
-- Resolves a native Silk recipe by requiring its file from weave/recipes/.

local function resolve(name)
  local ok, recipe = pcall(require, "weave.recipes." .. name)
  if not ok then
    error(string.format(
      "no native recipe found for '%s' (expected weave/recipes/%s.lua): %s",
      name, name, recipe
    ))
  end
  return recipe
end

local M = {}
M.resolve = resolve
return M
