-- weave/sources/aur.lua
-- Per design (tech reference 9b-1): git clone the AUR repo directly
-- (not the RPC API), since makepkg needs the real PKGBUILD anyway.
-- Dependencies are auto-parsed from the PKGBUILD's depends()/makedepends()
-- arrays, including version constraints where present.

local shell = require("weave.util.shell")

local AUR_CACHE_DIR = "/silk/weave/cache/aur"

local function resolve(name)
  local repo_url = "https://aur.archlinux.org/" .. name .. ".git"
  local clone_dir = AUR_CACHE_DIR .. "/" .. name

  -- Clone if we don't already have it, otherwise pull latest.
  local ok, out
  if shell.run("test -d " .. clone_dir .. "/.git") then
    ok, out = shell.run("git -C " .. clone_dir .. " pull --ff-only")
  else
    ok, out = shell.run("git clone " .. repo_url .. " " .. clone_dir)
  end
  if not ok then
    error(string.format("aur: failed to clone/update '%s': %s", name, out))
  end

  -- Source the PKGBUILD once and echo everything we need in one shot:
  -- version, plus depends()/makedepends() arrays.
  local read_ok, read_out = shell.run(
    "bash -c \"cd " .. clone_dir .. " && source PKGBUILD && " ..
    "echo $pkgver-$pkgrel && echo \\\"${depends[@]}\\\" \\\"${makedepends[@]}\\\"\""
  )
  if not read_ok then
    error(string.format("aur: failed to read PKGBUILD for '%s': %s", name, read_out))
  end

  local lines = {}
  for line in read_out:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  local version = lines[1]
  local dep_line = lines[2] or ""

  -- Parse each dependency word: "glibc>=2.38" -> {name, constraint},
  -- or a bare "glibc" -> plain string with no constraint.
  local depends = {}
  for dep in dep_line:gmatch("%S+") do
    local bare_name, op, ver = dep:match("^([^<>=]+)([<>=]+)(.+)$")
    if bare_name then
      table.insert(depends, { name = bare_name, constraint = op .. ver })
    elseif dep ~= "" then
      table.insert(depends, dep)
    end
  end

  return {
    name = name,
    version = version,
    source = {
      kind = "aur",
      repo_url = repo_url,
    },
    depends = depends,
    acquire = {
      steps = {
        {
          -- Root/loom-build privilege handoff (chown destdir,drop to loom-build, chown back) happens in the executor whenever it sees source.kind == "aur",
          -- not encoded here. This just describes the command that runs once privileges are dropped.
          cmd = "cd " .. clone_dir .. " && makepkg --nodeps -sf --noconfirm",
          confirm = string.format(
            "About to build AUR package '%s' from %s using makepkg. Continue?",
            name, repo_url
          ),
        },
      },
    },
  }
end

local M = {}
M.resolve = resolve
return M
