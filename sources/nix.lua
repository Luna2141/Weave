-- weave/sources/nix.lua
-- Per design (tech reference 9b-1): live nix resolution, full closure
-- copied into ctx.destdir, original store hash preserved as identity.
--
-- Flakes-only for now (deliberate scope decision) -- assumes a
-- flakes-enabled `nix` with a "nixpkgs" flake reference available.
-- Classic-channel support (`nix-build '<nixpkgs>' -A name`) can be
-- added later as a fallback if needed.

local shell = require("weave.util.shell")

local function resolve(name)
  local path_ok, store_path = shell.run(
    "nix eval --raw nixpkgs#" .. name .. ".outPath"
  )
  if not path_ok then
    error(string.format("nix: failed to resolve store path for '%s': %s", name, store_path))
  end

  -- Full transitive closure -- every store path this package needs
  -- at runtime, including its own glibc/openssl/etc.
  local closure_ok, closure_out = shell.run("nix-store -qR " .. store_path)
  if not closure_ok then
    error(string.format("nix: failed to compute closure for '%s': %s", name, closure_out))
  end

  local closure_paths = {}
  for line in closure_out:gmatch("[^\r\n]+") do
    table.insert(closure_paths, line)
  end

  -- Version isn't handed back as a separate field -- pull it out of
  -- the store path's own name (".../hash-name-version" -> "version").
  -- Best-effort; falls back to "unknown" rather than erroring, since
  -- this is just metadata, not something resolution depends on.
  local version = store_path:match("^/nix/store/[^%-]+%-[^%-]+%-(.+)$") or "unknown"

  -- One copy step per closure path, preserving each path's original
  -- hash-named directory under ctx.destdir -- this is what keeps the
  -- Nix-store identity/traceability the design called for.
  -- NOTE: ${ctx.destdir} below is a placeholder -- executor.lua does
  -- not yet support substituting ctx values into cmd strings. This is
  -- a real, outstanding requirement for executor.lua, not a bug here.
  local copy_steps = {}
  for _, path in ipairs(closure_paths) do
    table.insert(copy_steps, {
      cmd = "cp -a --parents " .. path .. " ${ctx.destdir}",
    })
  end

  return {
    name = name,
    version = version,
    source = {
      kind = "nix",
      store_path = store_path,
    },
    depends = {},
    acquire = {
      steps = {
        {
          -- Implicit disclosure per design -- fires for every
          -- Nix-sourced package, not hand-authored per recipe.
          cmd = "true",
          confirm = string.format(
            "'%s' will install alongside its own isolated dependency closure " ..
            "(%d store paths, including its own copies of libraries SilkOS already " ..
            "has natively). Continue?",
            name, #closure_paths
          ),
        },
        table.unpack(copy_steps),
      },
    },
  }
end

local M = {}
M.resolve = resolve
return M
