-- debug附加包，不会自动导入，需要调试时手动导入
unifuncex = unifuncex or {}
local _debug = {}


-- 获取模块地址
_debug.source = debug.getinfo(1, "S").source
unifuncex.Dir = _debug.source:match("@?(.*/)")


-- 获取并更新模块地址
function _debug.getDir()
  _debug.source = debug.getinfo(1, "S").source
unifuncex.Dir = _debug.source:match("@?(.*/)")
  return unifuncex.Dir
end


-- 重新载入本模块，令其返回私有函数表
function _debug.getPrivate(force_reload)
  if unifuncex.Private and not force_reload then
    return unifuncex.Private
  end
  local file = assert(io.open(unifuncex.Dir.."init.lua", "r"))
  local chunk = file:read("*a")
  file:close()
  chunk = chunk.."\nlocal _L = get_L(2)\nreturn _L"
  unifuncex.Private = assert(load(chunk))()
  return unifuncex.Private
end


rawset(unifuncex, "debug", _debug)