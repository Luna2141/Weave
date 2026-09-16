return {
  name = " ",            -- package name
  version = " ",         -- package version number
  source = {
    kind = "native",     -- package type IE: AUR, Deb, Nix, or native
    url = " ",           -- source url
    checksum = " ",      --md5 checksum
    patches = {
      " ",               -- patch if needed
    },
  },
  depends = { " " },   --dependcies
  acquire = {          -- steps needed to aquire package
    steps = {
      { cmd = " " },
    },
  },
}
