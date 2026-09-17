-- weave/executor.lua
-- Runs a resolved Recipe's acquire.steps, building and threading a ctx
-- table through each step.

local shell = require("weave.util.shell")

-- Builds the ctx table passed to every step.
local function build_ctx(recipe, opts)
  opts = opts or {}
  local srcdir = "/silk/weave/build/" .. recipe.name
  return {
    name = recipe.name,
    version = recipe.version,
    flavor = opts.flavor or "glibc",
    arch = opts.arch or "x86_64",
    destdir = "/silk/weave/destdir/" .. recipe.name,
    srcdir = srcdir,
    workdir = srcdir,
    env = opts.env or {},
    log = function(msg) print("[" .. recipe.name .. "] " .. msg) end,
  }
end

-- Replaces ${ctx.field} references inside a cmd string with the real
-- value from ctx.
local function substitute(cmd, ctx)
  return (cmd:gsub("%${ctx%.([%w_]+)}", function(field)
    local val = ctx[field]
    if val == nil then
      error("substitute: ctx has no field '" .. field .. "'")
    end
    return tostring(val)
  end))
end

-- Returns true if stdin is an interactive terminal.
local function is_interactive()
  return shell.run("test -t 0")
end

-- Returns "proceed" or "decline". Errors if confirmation is required
-- but impossible (non-interactive, no --yes given).
local function confirm_step(step, opts)
  if not step.confirm then
    return "proceed"
  end
  if opts.yes then
    return "proceed"
  end
  if not is_interactive() then
    error(string.format(
      "step requires confirmation but is running non-interactively: \"%s\"\n" ..
      "re-run with --yes, or run interactively to confirm manually.",
      step.confirm
    ))
  end

  io.write(step.confirm .. " [y/N] ")
  io.flush()
  local answer = io.read("*l")
  if answer and answer:lower() == "y" then
    return "proceed"
  end
  return "decline"
end

-- Runs one step (cmd or fn).
local function run_step(step, ctx, opts)
  local decision = confirm_step(step, opts)
  if decision == "decline" then
    ctx.log("declined at step: " .. step.confirm)
    error("build aborted: user declined confirmation step", 0)
  end

  if step.fn then
    step.fn(ctx)
    return
  end

  -- Every cmd step runs starting from ctx.workdir, so recipes don't
  -- each have to know/repeat where the executor happens to be running.
  local resolved_cmd = "cd " .. ctx.workdir .. " && " .. substitute(step.cmd, ctx)

  if ctx.source_kind == "aur" then
    resolved_cmd = "sudo -u loom-build " .. resolved_cmd
  end

  local ok, output = shell.run(resolved_cmd)
  ctx.log(resolved_cmd)
  if not ok then
    error(string.format("step failed: %s\n%s", resolved_cmd, output))
  end
end

-- Runs every step in a recipe's acquire block, picking the flavor
-- override if present.
local function run(recipe, opts)
  opts = opts or {}
  local ctx = build_ctx(recipe, opts)
  ctx.source_kind = recipe.source and recipe.source.kind

  local steps = recipe.acquire and recipe.acquire["steps_" .. ctx.flavor]
  steps = steps or (recipe.acquire and recipe.acquire.steps) or {}

  -- AUR handoff, per design: root creates+chowns destdir once before
  -- any step runs, chowns back to root once after all steps complete.
  if ctx.source_kind == "aur" then
    shell.run("mkdir -p " .. ctx.destdir)
    shell.run("chown loom-build:loom-build " .. ctx.destdir)
  end

  for _, step in ipairs(steps) do
    run_step(step, ctx, opts)
  end

  if ctx.source_kind == "aur" then
    shell.run("chown -R root:root " .. ctx.destdir)
  end

  return ctx
end

local M = {}
M.build_ctx = build_ctx
M.substitute = substitute
M.run = run
return M
