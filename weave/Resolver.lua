-- weave/resolver.lua

local parser = require("weave.parser")
local schema = require("weave.schema")
local version = require("weave.util.version")

-- Maps a source kind to its module path. NOT required eagerly -- each
-- one is only require()'d the first time it's actually needed, so a
-- resolve involving only native packages works fine even if
-- sources/aur.lua, nix.lua, or deb.lua don't exist yet.
local SOURCE_MODULES = {
  native = "weave.sources.native",
  aur    = "weave.sources.aur",
  nix    = "weave.sources.nix",
  deb    = "weave.sources.deb",
}

local loaded_sources = {} -- cache, so each module is require()'d at most once

local function get_source(kind)
  if loaded_sources[kind] then
    return loaded_sources[kind]
  end

  local module_path = SOURCE_MODULES[kind]
  if not module_path then
    error("unknown source kind: " .. tostring(kind))
  end

  local ok, mod = pcall(require, module_path)
  if not ok then
    error(string.format(
      "source kind '%s' is not available (failed to load %s): %s",
      kind, module_path, mod
    ))
  end

  loaded_sources[kind] = mod
  return mod
end

-- Turns a parsed {name, kind} into a full, validated Recipe.
local function resolve_package_string(pkg_string)
  local parsed = parser.parse_package_string(pkg_string)

  local source_module = get_source(parsed.kind)
  local recipe = source_module.resolve(parsed.name)

  local valid, err = schema.validate(recipe, parsed.kind)
  if not valid then
    error(string.format("recipe '%s' failed validation: %s", parsed.name, err))
  end

  return recipe
end

local function resolve_all(package_strings)
  local resolved = {}
  local order = {}
  local visiting = {}

  local function visit(name)
    if resolved[name] then
      return
    end
    if visiting[name] then
      error("Circular dependency detected involving: " .. name)
    end

    visiting[name] = true

    local recipe = resolve_package_string(name)
    resolved[name] = recipe

    for _, dep in ipairs(recipe.depends) do
      local dep_name = type(dep) == "table" and dep.name or dep
      local dep_constraint = type(dep) == "table" and dep.constraint or nil

      visit(dep_name)

      if dep_constraint then
        local dep_recipe = resolved[dep_name]
        if not version.satisfies(dep_recipe.version, dep_constraint) then
          error(string.format(
            "dependency constraint not satisfied: '%s' requires %s%s, but resolved version is %s",
            recipe.name, dep_name, dep_constraint, dep_recipe.version
          ))
        end
      end
    end

    visiting[name] = nil
    table.insert(order, name)
  end

  for _, pkg_string in ipairs(package_strings) do
    visit(pkg_string)
  end

  return {
    recipes = resolved,
    order = order,
  }
end

local M = {}
M.resolve_package_string = resolve_package_string
M.resolve_all = resolve_all
return M
