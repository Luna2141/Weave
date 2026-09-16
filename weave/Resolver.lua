-- weave/resolver.lua

local parser = require("weave.parser")
local schema = require("weave.schema")

-- Turns a parsed {name, kind} into a full, validated Recipe.
local function resolve_package_string(pkg_string)
  local parsed = parser.parse_package_string(pkg_string)

  local recipe

  if parsed.kind == "native" then
    -- Native recipes live at weave/recipes/<name>.lua, authored from
    -- the recipes/recipe.lua template.
    local ok, loaded = pcall(require, "weave.recipes." .. parsed.name)
    if not ok then
      error(string.format(
        "no native recipe found for '%s' (expected weave/recipes/%s.lua): %s",
        parsed.name, parsed.name, loaded
      ))
    end
    recipe = loaded
  else
    -- aur / nix / deb: not yet implemented, needs sources/*.lua
    error(string.format(
      "resolve_package_string: source kind '%s' not yet implemented (sources/%s.lua doesn't exist yet)",
      parsed.kind, parsed.kind
    ))
  end

  local valid, err = schema.validate(recipe, parsed.kind)
  if not valid then
    error(string.format("recipe '%s' failed validation: %s", parsed.name, err))
  end

  return recipe
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
M.resolve_package_string = resolve_package_string
M.resolve_all = resolve_all
return M
