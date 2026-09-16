return {
  name = "lua",                                       -- package name
  version = "5.4.7 ",                                 -- package version number
  source = {
    kind = "native",                                  -- package type IE: AUR, Deb, Nix, or native
    url = "https://www.lua.org/ftp/lua-5.4.7.tar.gz", -- source url
    checksum = "fc3f3291353bbe6ee6dec85ee61331e8",    --md5 checksum
    patches = {
      "lua-5.4.7-shared_library-1.patch",             -- patch if needed
    },
  },
  depends = { '' }, -- dependcies
  acquire = {       -- steps needed to aquire package
    steps = {
      { cmd = "file lua-5.4.7.tar.gz" },
      { cmd = "'echo fc3f3291353bbe6ee6dec85ee61331e8  /weave/recipes/lua-5.4.7.tar.gz' | md5sum --check" },
      { cmd = "tar -xf lua-5.4.7.tar.gz" },
      { cmd = "cd lua-5.4.7" },
      { cmd = "patch -Np1 -i ../lua-5.4.7-shared_library-1.patch" },
      { cmd = "make linux" },
      { cmd = "make INSTALL_TOP=/usr | INSTALL_DATA='cp -d' | INSTALL_MAN=/usr/share/man/man1 | TO_LIB='liblua.so liblua.so.5.4 liblua.so.5.4.7' | install" },
    },
  },
}
