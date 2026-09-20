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
-- against the recipe's own source.kind.
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

  -- depends: each entry is either a bare name (string, no constraint)
  -- or a { name = "...", constraint = "..." } table.
  if recipe.depends ~= nil then
    if type(recipe.depends) ~= "table" then
      return false, "recipe.depends must be a table (array) if present"
    end
    for i, dep in ipairs(recipe.depends) do
      if type(dep) == "table" then
        if type(dep.name) ~= "string" or dep.name == "" then
          return false, string.format("depends[%d].name must be a non-empty string", i)
        end
        if dep.constraint ~= nil and type(dep.constraint) ~= "string" then
          return false, string.format("depends[%d].constraint must be a string if present", i)
        end
      elseif type(dep) ~= "string" then
        return false, string.format("depends[%d] must be a string or a {name, constraint} table", i)
      end
    end
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
      if step.confirm ~= nil and type(step.confirm) ~= "string" then
        return false, string.format("acquire.steps[%d].confirm must be a string if present", i)
      end
    end
  end

  return true
end

-- Returns a human-editable template string, generated from this file,
-- so the recipe template can never drift out of sync with the real shape.
local function template()
  return [[
-- Copy this file to weave/recipes/<name>.lua and fill in the fields.
return {
    name = "...",
    version = "...",
    source = {
        kind = "native",
    },
    depends = {
        -- "some-package",                              -- no version constraint
        -- { name = "some-package", constraint = ">=1.2" },  -- with a constraint
    },
    acquire = {
        steps = {
            -- { cmd = "make install", confirm = "About to do X. Continue?" },
            -- { fn = function(ctx) ... end },
        },
    },
}
]]
end

local M = {}
M.Recipe = Recipe
M.validate = validate
M.template = template
return M
