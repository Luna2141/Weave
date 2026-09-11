-- weave/resolver.lua

local function resolve_all(package_strings)
  local resolved = {}   -- name -> Recipe, deduped:
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

    local recipe = resolve_package_string(name)     -- from the parser
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
