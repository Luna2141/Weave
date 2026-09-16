-- weave/schema.lua

-- Every recipe, regardless of source, normalizes to this shape
-- after being processed by a source-specific constructor (weave.nix, weave.aur, etc.)
local Recipe = {
  name = nil,
  version = nil,
  source = nil,
  depends = {},
  acquire = nil,
}

-- Validates a recipe table against the schema shape.
-- expected_kind (optional): the kind the PARSER derived from the package
-- string (e.g. "aur" from "neovim.aur"). If given, it's cross-checked
-- against the recipe's own source.kind — a mismatch means the recipe
-- file disagrees with how it was referenced, which is a real bug.
-- Returns true, or false + an error message string.
local function validate(recipe, expected_kind)
  if type(recipe) ~= "table" then
    return false, "recipe must be a table"
  end

  if type(recipe.name) ~= "string" or recipe.name == "" then
    return false, "recipe.name must be a non-empty string"
  end

  if type(recipe.version) ~= "string" or recipe.version == "" then
    return false, "recipe.version must be a non-empty string"
  end

  if type(recipe.source) ~= "table" then
    return false, "recipe.source must be a table"
  end

  if type(recipe.source.kind) ~= "string" then
    return false, "recipe.source.kind must be a string"
  end

  if expected_kind and recipe.source.kind ~= expected_kind then
    return false, string.format(
      "kind mismatch for '%s': parser expected '%s' but recipe declares source.kind = '%s'",
      recipe.name, expected_kind, recipe.source.kind
    )
  end

  if recipe.depends ~= nil and type(recipe.depends) ~= "table" then
    return false, "recipe.depends must be a table (array) if present"
  end

  if recipe.acquire ~= nil then
    if type(recipe.acquire) ~= "table" then
      return false, "recipe.acquire must be a table if present"
    end
    if recipe.acquire.steps ~= nil and type(recipe.acquire.steps) ~= "table" then
      return false, "recipe.acquire.steps must be a table (array) if present"
    end
    for i, step in ipairs(recipe.acquire.steps or {}) do
      if type(step) ~= "table" then
        return false, string.format("acquire.steps[%d] must be a table", i)
      end
      if not step.cmd and not step.fn then
        return false, string.format("acquire.steps[%d] must have a 'cmd' or 'fn'", i)
      end
    end
  end

  return true
end

local M = {}
M.Recipe = Recipe
M.validate = validate
return M
