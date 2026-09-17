return {
  name = "lua",
  version = "5.4.7",
  source = {
    kind = "native",
    url = "https://www.lua.org/ftp/lua-5.4.7.tar.gz",
    checksum = "fc3f3291353bbe6ee6dec85ee61331e8",
    patches = {
      "lua-5.4.7-shared_library-1.patch",
    },
  },
  depends = {},

  acquire = {
    steps = {
      { cmd = "curl -LO https://www.lua.org/ftp/lua-5.4.7.tar.gz" },
      { cmd = "echo 'fc3f3291353bbe6ee6dec85ee61331e8  lua-5.4.7.tar.gz' | md5sum -c -" },
      { cmd = "file lua-5.4.7.tar.gz" },
      { cmd = "tar -xf lua-5.4.7.tar.gz" },
      { cmd = "cd lua-5.4.7 && patch -Np1 -i ../lua-5.4.7-shared_library-1.patch" },
      { cmd = "cd lua-5.4.7 && make linux" },
      {
        -- INSTALL_TOP now points inside ctx.destdir, not the live /usr --
        -- this is staged output, not a real system install.
        cmd =
        "cd lua-5.4.7 && make INSTALL_TOP=${ctx.destdir}/usr INSTALL_DATA='cp -d' INSTALL_MAN=${ctx.destdir}/usr/share/man/man1 TO_LIB='liblua.so liblua.so.5.4 liblua.so.5.4.7' install",
        confirm = "About to build and stage Lua into its destdir. Continue?",
      },
      { cmd = "cd lua-5.4.7 && mkdir -pv ${ctx.destdir}/usr/share/doc/lua-5.4.7 && cp -v doc/*.html doc/*.css doc/*.gif doc/*.png ${ctx.destdir}/usr/share/doc/lua-5.4.7" },
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
      { cmd = "cd lua-5.4.7 && install -v -m644 -D lua.pc ${ctx.destdir}/usr/lib/pkgconfig/lua.pc" },
    },
  },
}
