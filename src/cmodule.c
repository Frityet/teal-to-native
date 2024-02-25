#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


static int l_hello(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    printf("Hello, %s!\n", name);
    return 1;
}

static const struct luaL_Reg mylib[] =
{
    {"hello", l_hello},
    {NULL, NULL}
};

int luaopen_cmodule(lua_State *L)
{
    luaL_newlib(L, mylib);
    return 1;
}
