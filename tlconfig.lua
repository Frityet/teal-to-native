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
    }
}
