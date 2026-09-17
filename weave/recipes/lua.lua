return {
  name = "lua",                                       -- package name
  version = "5.4.7",                                  -- package version number
  source = {
    kind = "native",                                  -- package type IE: AUR, Deb, Nix, or native
    url = "https://www.lua.org/ftp/lua-5.4.7.tar.gz", -- source url
    checksum = "fc3f3291353bbe6ee6dec85ee61331e8",    -- md5 checksum
    patches = {
      "lua-5.4.7-shared_library-1.patch",             -- patch if needed
    },
  },
  depends = {}, -- dependencies

  acquire = {   -- steps needed to acquire package
    steps = {
      { cmd = "file lua-5.4.7.tar.gz" },
      { cmd = "tar -xf lua-5.4.7.tar.gz" },
      { cmd = "cd lua-5.4.7 && patch -Np1 -i ../lua-5.4.7-shared_library-1.patch" },
      { cmd = "cd lua-5.4.7 && make linux" },
      {
        cmd =
        "cd lua-5.4.7 && make INSTALL_TOP=/usr INSTALL_DATA='cp -d' INSTALL_MAN=/usr/share/man/man1 TO_LIB='liblua.so liblua.so.5.4 liblua.so.5.4.7' install",
        confirm = "About to install Lua system-wide to /usr. Continue?",
      },
      { cmd = "cd lua-5.4.7 && mkdir -pv /usr/share/doc/lua-5.4.7 && cp -v doc/*.html doc/*.css doc/*.gif doc/*.png /usr/share/doc/lua-5.4.7" },
      {
        fn = function(ctx)
          local f = io.open(ctx.workdir .. "/lua-5.4.7/lua.pc", "w")
          f:write([[
V=5.4
R=5.4.7

prefix=/usr
INSTALL_BIN=${prefix}/bin
INSTALL_INC=${prefix}/include
INSTALL_LIB=${prefix}/lib
INSTALL_MAN=${prefix}/share/man/man1
INSTALL_LMOD=${prefix}/share/lua/${V}
INSTALL_CMOD=${prefix}/lib/lua/${V}
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: Lua
Description: An Extensible Extension Language
Version: ${R}
Requires:
Libs: -L${libdir} -llua -lm -ldl
Cflags: -I${includedir}
]])
          f:close()
        end,
      },
      { cmd = "cd lua-5.4.7 && install -v -m644 -D lua.pc /usr/lib/pkgconfig/lua.pc" },
    },
  },
}
