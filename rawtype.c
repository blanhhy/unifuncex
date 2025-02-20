#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int rawtype(lua_State *L) {
    luaL_checkany(L, 1);  // 确保至少有一个参数
    int type = lua_type(L, 1);  // 获取原始类型
    const char* type_name = lua_typename(L, type);  // 转换为类型名称
    lua_pushstring(L, type_name);  // 将结果压入栈
    return 1;  // 返回1个结果
}

// 模块入口函数
int luaopen_rawtype(lua_State *L) {
    lua_pushcfunction(L, rawtype);
    return 1;
}