return {
    build_dir = "build",
    source_dir = "src",
    include_dir = {
        "types/",
        "src/",
        "lua_modules/share/lua/5.4/"
    },
    gen_compat = "off",
    scripts = {
        build = {
            post = "scripts/aot-compile.tl"
        }
    },
    dont_prune = {
        "build/bin",
        "build/bin/main",
    },
    aot_options = {
        cflags = {
            "-Os",
        },
        ldflags = {
            "-fPIC",
            "-flto"
        },
        verbose = false,
        include_luarocks_modules = true,
    }
}
