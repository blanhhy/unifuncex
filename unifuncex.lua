--封装type函数
if rawequal(type(setmetatable({"unifuncex"}, { __type = function(self) return self[1] end })), "unifuncex") then
  -- 如果已经被封装，则导入备用的c包
  rawtype = require "rawtype"
 else
  rawtype = type
  function type(var)
    local _type = rawtype(var)
    local meta = getmetatable(var)
    return meta and meta.__type and meta.__type(var) or _type
  end
end



-- 检查变量通过某函数后的返回值是否符合预期
function checkreturn(func, ...)
  local args = {...}
  local args_n = #args
  local n = args_n >> 1
  if args_n & 1 == 1 then
    table.insert(args, "any")
    n = n + 1
  end
  for i = 1, n do
    local success, actual_or_err = pcall(func, args[i])
    local expected = args[i + n]
    if not success then
      return false, i, actual_or_err -- 函数运行错误，返回出错位置与原始错误信息
    end
    if expected ~= "any" and expected ~= actual_or_err then
      return false, i, n -- 不符合预期，返回第一个意外的位置和检查的次数
    end
  end
  return true, n, n -- 符合预期，返回最终位置和检查的次数（两者相等）
end



-- 检查参数类型
local function checkargs(...)
  local result, rupt, n = checkreturn(...)
  local type = ...
  return result or error(string.format("bad argument #%s to '%s' (%s expected, got %s)", rupt , debug.getinfo(2, "n").name or "unknown function", select( 1 + last + n, ...), type(select( 1 + last, ...))), 3)
end



-- 变成布尔（0是false）
function toboolean(value)
  return value ~= nil and value ~= false and value ~= 0
end



-- 广义异或运算
function xor(x, y)
  local bx = toboolean(x)
  local by = toboolean(y)
  -- 同真同假返回false
  if bx == by then
    return false
  end
  -- 否则返回真的那个值
  return bx and x or y
end



-- 广义同或运算
function xnor(x, y)
  local bx = toboolean(x)
  local by = toboolean(y)
  -- 同真返回原来两个值
  if bx and by then
    return x, y
  end
  -- 同假返回true，一真一假返回false
  return bx == by
end



-- 尝试转为数字
function trytonumber(value)
  return tonumber(value) or value
end



-- 尝试改变数据类型
function string.tryto(str)
  return str == "true" or str ~= "false" and trytonumber(str)
end



-- 获取上层栈的局部变量表
local function get_L(level)
  local _L = {}
  local cur_index = 1
  while true do
    local var_name, var_value = debug.getlocal(level, cur_index)
    if not var_name then break end
    _L[var_name] = var_value
    cur_index = cur_index + 1
  end
  return _L
end



-- 所有的访问等级
-- 访问等级用一个三进制两位数表示，用它的十进制数储存
-- 高位控制局部变量，低位控制全局变量
-- 0代表禁用，1代表只读，2代表可写
-- 只读限定对table中的域无效，table可读域就可写
local exe = {
  -- 01: 局部变量禁用，全局变量只读
  [1] = function(str)
    local env = setmetatable({}, { __index = _G })
    return assert(load(str, str, "t", env))()
  end,
  -- 02: 局部变量禁用，全局变量可写
  [2] = function(str)
    return assert(load(str, str, "t"))()
  end,
  -- 10: 局部变量只读，全局变量禁用
  [3] = function(str)
    local env = get_L(3)
    if env._ENV == _G then env._ENV = nil end
    return assert(load(str, str, "t", env))()
  end,
  -- 11: 局部变量只读，全局变量只读
  [4] = function(str)
    local env = setmetatable(get_L(3), { __index = _G })
    if env._ENV == _G then env._ENV = nil end
    return assert(load(str, str, "t", env))()
  end,
  -- 12: 局部变量只读，全局变量可写
  [5] = function(str)
    local env = get_L(3)
    if env._ENV == _G then env._ENV = nil end
    setmetatable(env, { __index = _G, __newindex = _G })
    return assert(load(str, str, "t", env))()
  end
}



-- 执行文本代码
function execute(str, aces_lv, env)
  if env or rawtype(aces_lv) == "table" then
    -- 只要指定了环境，所有外部变量都禁用
    return assert(load(str, str, "t", env or aces_lv))()
  end
  return exe[aces_lv or 4](str) -- 默认全只读
end



-- 格式化输出
function printf(str, ...)
  print(type(str) == "string" and str:format(...) or tostring(str))
end



-- 执行shell命令并返回shell输出
local function push_command(command, inTerminal)
  local handle = assert(io.popen(command), "Failed to open pipe for command: "..command)
  local result = handle:read("*a")
  local status = handle:close()
  assert(status, "Failed to close handle after command: "..command)
  return result
end



shell = {
  __call = function(self, ...)
    return push_command(...)
  end,
  __index = function(self, cmd)
    return function(...)
      local args = { cmd, ... }
      return push_command(table.concat(args, " "))
    end
  end,
}
shell.sh = shell
setmetatable(shell, shell)



-- 创建多级目录
function mkdirs(path)
  local File = luajava.bindClass "java.io.File"
  path = File(path)
  if not path.exists() then
    mkdirs(path.getParentFile().toString())
    path.mkdir()
  end
end



-- 创建文件（自动新建目录）
function mkfile(path)
  mkdirs(path: match("^(.+)/[^/]+$"))
  io.open(path, "w"): close()
end



-- 列出完整表格
local function tb_to_str(tb, max_depth, indent)
  if rawtype(tb) ~= "table" then
    return tostring(tb)
  end
  indent = indent or 0
  max_depth = max_depth or 10 -- 默认最大递归深度 10
  if indent >= max_depth then
    return tostring(tb) -- 超过最大深度时省略，防止栈溢出
  end
  local str_list = {}
  local prefix = string.rep("  ", indent)
  for key, value in next, tb do
    local key_str = rawtype(key) == "string" and string.format("[\"%s\"]", key) or string.format("[%s]", tostring(key))
    local value_str = value ~= _G and (value ~= tb and tb_to_str(value, max_depth, indent + 1) or "__self") or "_G" -- 排除_G与自引用，防止栈溢出
    table.insert(str_list, prefix .. key_str .. " = " .. value_str)
  end
  return "{\n" .. table.concat(str_list, ",\n") .. "\n" .. string.rep("  ", indent - 1) .. "}"
end



-- 数组转字符串
function table.tostring(tb, sep, _start, _end)
  if rawtype(tb) ~= "table" then
    return tostring(tb)
  end
  local str_list = {}
  for i = 1, #tb do
    rawset(str_list, i, tostring(tb[i]))
  end
  return sep and table.concat(str_list, sep, _start, _end) or "{ " .. table.concat(str_list, ", ", _start, _end) .. " }"
end


-- 打印完整表格（支持多个参数）
function printt(...)
  local params = table.pack(...)
  for i = 1, params.n do
    params[i] = tb_to_str(params[i])
  end
  print(table.unpack(params, 1, params.n))
end



-- 打印完整表格（支持指定深度）
function table.print(tb, max_depth)
  if max_depth then
    print(tb_to_str(tb, max_depth))
   else
    print(table.tostring(tb))
  end
end



-- 获取表中元素数量
function table.len(tb)
  local len = 0
  for aaa in next, tb do
    len = len + 1
  end
  return len
end



-- 获取表中最大正整数索引
table.maxn = table.maxn or function(tb)
  checkargs(rawtype, tb, "table")
  local max = 0
  for index in next, tb do
    max = type(index) == "number" and index > max and index == math.floor(index) and index or max
  end
  return max
end



-- 用表2的值覆盖表1
function table.override(tb1, tb2)
  checkargs(rawtype, tb1, tb2, "table", "table")
  for key, value in next, tb2 do
    tb1[key] = value
  end
  return tb1
end



-- 继承所有键值对
function table.inherit(tb)
  return table.override({}, tb)
end



-- 合并table（索引相同的后一个覆盖前一个）
function table.collect(tb1, tb2)
  checkargs(rawtype, tb1, tb2, "table", "table")
  local result = table.inherit(tb1)
  for key, value in next, tb2 do
    result[key] = value
  end
  return result
end



-- 完全复制 table（不继承元表）
function table.copy(tb, seen)
  if rawtype(tb) ~= "table" then
    return tb -- 非 table 类型直接返回自身
  end
  if seen and seen[tb] then
    return seen[tb] -- 处理循环引用
  end
  local new = {}
  seen = seen or {} -- 记录已复制的表，避免重复
  rawset(seen, tb, new)
  for key, value in next, tb do
    rawset(new, key, table.copy(value, seen))
  end
  return new
end



-- 完全复制 table（继承元表）
table.clone = table.clone or function(tb)
  return setmetatable(table.copy(tb), getmetatable(tb))
end



-- 分离table的非数组部分与数组部分
function table.detach(tb)
  local array = {}
  local hash = {}
  for key, value in next, tb do
    if type(key) == "number" and key > 0 and key == math.floor(key) then
      rawset(array, key, value)
     else
      rawset(hash, key, value)
    end
  end
  return hash, array
end