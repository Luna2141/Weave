-- weave/schema.lua

-- Every recipe, regardless of source, normalizes to this shape
-- after being processed by a source-specific constructor (weave.nix, weave.aur, etc.)
local Recipe = {
    name = nil,        -- string, required. e.g. "ripgrep-all"
    version = nil,      -- string, required. e.g. "0.10.9"
    source = nil,        -- table, required. Source-specific (see below)
    depends = {},        -- array of recipe names (strings), for resolution ordering
    build = nil,          -- optional function or table describing build steps
}
