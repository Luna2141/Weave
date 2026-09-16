return {
  name = "Lua",                                           -- package name
  version = "5.4.7 ",                                     -- package version number
  source = {
    kind = "native",                                      -- package type IE: AUR, Deb, Nix, or native
    url = "https://www.lua.org/ftp/lua-5.4.7.tar.gz",     -- source url
    checksum = "fc3f3291353bbe6ee6dec85ee61331e8",        --md5 checksum
    patches = {
      "lua-5.4.7-shared_library-1.patch",                 -- patch if needed
    },
  },
  depends = { "" },   --dependcies
  acquire = {         -- steps needed to aquire package
    steps = {
      { cmd = "make linux" },
      { cmd = "make install --INSTALL_TOP --TO_LIB  " },
    },
  },
}
