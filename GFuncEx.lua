--自定义数据类型
Type=type

function type(var)
  if Type(var) == "table" and var.__user_custom_data_type__ then
    return var.__user_custom_data_type__
   else
    return Type(var)
  end
end



--补全异或&同或运算
function xor(x, y)
  x = toboolean(x)
  y = toboolean(y)
  if x == y then
    return false
   else
    return true
  end
end

function nxor(x, y)
  return not xor(x, y)
end



--尝试转为数字
function trytonumber(source)
  local result = tonumber(source)
  if result then
    return result
   else
    return source
  end
end



--变成布尔（0是false）
function toboolean(value)
  if trytonumber(value) == 0 or value == "false" then
    return false
   elseif value then
    return true
   else
    return false
  end
end



--尝试改变数据类型
function string.tryto(str)
  if str == "true" then
    return true
   elseif str == "false" then
    return false
   elseif string.sub(str, 1, 8) == "function" and string.sub(str, -3) == "end" then
    return loadstring(str)
   else
    return trytonumber(str)
  end
end



--执行文本代码
function execute(str)
  assert(loadstring(str))()
end



--执行shell命令并返回shell输出
function shell(command, inTerminal)
  local handle = io.popen(command)
  local result = handle: read("*a")
  handle: close()
  if inTerminal then
    return result
   else
    result = string.sub(result, 1, -2)
    if command: find("echo") then
      print(result)
    end
    return result
  end
end



--创建多级目录
function mkdirs(path)
  import "java.io.File"
  path = File(path)
  if not path.exists() then
    mkdirs(path.getParentFile().toString())
    path.mkdir()
  end
end



--创建文件（自动新建目录）
function mkfile(path)
  mkdirs(path: match("^(.+)/[^/]+$"))
  io.open(path, "w"): close()
end



--打印出完整表格
function printt(tb)
  local function tb_to_str(tb)
    if Type(tb) == "table"
      local str = ""
      for key, value in pairs(tb) do
        if str ~= "" then
          str = str.."\n"
        end
        str = str.."[ \""..tostring(key).."\" ] = "..tb_to_str(value)
      end
      return "{"..str.."}"
     else
      return tostring(tb)
    end
  end
  print(tb_to_str(tb))
end



--用表2的值覆盖表1
function table.override(tb1, tb2)
  if Type(tb1) == "table" and Type(tb2) == "table" then
    for key, value in pairs(tb2) do
      tb1[key] = value
    end
    return tb1
   else
    error("Params must be table values.")
  end
end



--复制table
function table.copy(tb)
  local new_table ={}
  return table.override(new_table, tb)
end



--求合集（索引相同的后一个覆盖前一个）
function table.collect(tb1, tb2)
  local result = table.copy(tb1)
  if Type(tb1) == "table" and Type(tb2) == "table" then
    local result = tb1
    for key, value in pairs(tb2) do
      result[key] = value
    end
    return result
   else
    error("Params must be table values.")
  end
end



--解散一个数组并输出变长参数
function table.disband(array, current)
  local length = #array
  if current then
    current = current + 1
   else
    current = 1
  end
  local current_value = array[current]
  array[current] = nil
  if length == 0 then
    return
   else
    return current_value, table.disband(array, current)
  end
end



--函数封装
function packMe(...)
  local function iter(methods, current)
    local length = #methods
    current = current + 1
    local current_value = methods[current]
    methods[current] = nil
    if length == 0 then
      return function end
     else
      return function(...)
        current_value(...)
        iter(methods, current)(...)
      end
    end
  end
  return iter({...}, 0)
end



--分离table的数组部分与非数组部分
function table.detach(tb, extract)
  local array = {}
  local non_array = table.copy(tb)
  for index = 1, #non_array do
    array[index] = non_array[index]
    non_array[index] = nil
  end
  if not extract then
    return non_array, array
   elseif extract == "array" then
    return array
   elseif extract == "non-array" then
    return non-array
   else
    return array, non_array
  end
end




