-- weave/resolver.lua

local parser = require("weave.parser")

-- TODO: this needs real logic to turn a parsed {name, kind} into a full Recipe:
--   - kind == "native"  -> require the matching file from weave/recipes/<name>.lua
--   - kind == "aur"/"nix"/"deb" -> hand off to sources/*.lua (not yet built)
-- Placeholder for now so the module loads; fill in once sources/*.lua exist.
local function resolve_package_string(pkg_string)
  local parsed = parser.parse_package_string(pkg_string)
  error("resolve_package_string: not yet implemented for kind '" .. parsed.kind .. "'")
end

local function resolve_all(package_strings)
  local resolved = {}   -- name -> Recipe, deduped
  local order = {}      -- final build order (array of names)
  local visiting = {}   -- for cycle detection (name -> true while in-progress)

  local function visit(name)
    if resolved[name] then
      return       -- already resolved, nothing to do
    end
    if visiting[name] then
      error("Circular dependency detected involving: " .. name)
    end

    visiting[name] = true

    local recipe = resolve_package_string(name)
    resolved[name] = recipe

    -- Recursively resolve dependencies first
    for _, dep_name in ipairs(recipe.depends) do
      visit(dep_name)
    end

    visiting[name] = nil
    table.insert(order, name)     -- deps are already in `order`
  end

  for _, pkg_string in ipairs(package_strings) do
    visit(pkg_string)
  end

  return {
    recipes = resolved,     -- name -> Recipe, for lookup
    order = order,          -- dependency-safe build order
  }
end

local M = {}
M.resolve_all = resolve_all
return M
