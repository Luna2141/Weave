-- Default recipe structure

{
    name = "...",
    version = nil,      -- filled in when source is queried
    source = { kind = "...", ... },  -- source-specific fields
    depends = {},
    build = nil,         -- not designed yet — next piece
}
