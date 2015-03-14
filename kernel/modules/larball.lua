local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function listAll(_path, _files)
  local path = _path or ""
  local files = _files or {}
  if #path > 1 then table.insert(files, path) end
  for _, file in ipairs(fs.list(path)) do
    local path = fs.combine(path, file)
    if fs.isDir(path) then
      listAll(path, files)
    else
      table.insert(files, path)
    end
  end
  return files
end

local function _do_tabling(file)
  if fs.isDir(file) then
    return
  end

  local handle = fs.open(file, 'r')
  local ret = {
    ['data'] = handle.readAll(),
    ['meta'] = {
      ['size'] = fs.getSize(file),
      ['path'] = file
    }
  }

  handle.close()
  return ret
end


local function _do_larring(dir)
  local list = listAll(dir)
  local ret = {}
  for i = 1, #list do
    table.insert(ret, _do_tabling(list[i]))
  end

  return ret
end

function _G.tt(str, size)
  if #str == 0 then return {} end

  local a,i = {},1
  repeat
    a[i] = str:sub(1,size)
    i = i + 1
    str = str:sub(size+1)
  until str == ''
  return a
end

local function _write_larball(file, data)
  local file_h = fs.open(file, 'w')
  local data = enc(textutils.serialize(data))
  local count = 0

  for k, v in pairs(tt(data, 64)) do
    file_h.writeLine(v)
    count = count + 1
    if count == 16 then
      file_h.writeLine('')
      count = 0
    end
  end
  file_h.close()
end

local function _do_unlarring(root, data)
  for i = 1, #data do
    local file = fs.open(fs.combine(root, data[i].meta.path), 'w')
    file.writeLineLine(data[i].data)
    file.close()
  end

end

local function _do_unlarballing(rootdir, file)
  local data = fs.open(file, 'r')
  local tab = textutils.unserialize(dec(data.readAll()))
  data.close()


  _do_unlarring(rootdir, tab)
end

local _lar = modules.module 'larballs' {
  text = {
    load = function()
      _G.larball = {
        ['lar'] = function(file, dir)
          _write_larball(file, _do_larring(dir))

        end,
        ['unlar'] = _do_unlarballing,
        ['unlarToRoot'] = function(file)
          _do_unlarballing('/', file)
        end,
      }
    end,
    unload = function()
      _G.larball = nil
    end
  }
}

local _base64 = modules.module 'base64' {
  text = {
    load = function()
      _G.base64 = {
        ['encode'] = enc,
        ['decode'] = dec,
      }
    end,
    unload = function()
      _G.base64 = nil
    end
  }
}

local function _se_append_header(file)
  file.writeLine('local b=\'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\'')
  file.writeLine([[
    local function dec(data)
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
  ]])

  file.flush()
end

local function _se_append_extractor(file, data)
  file.writeLine([[
    local function _do_unlarballing(root)
      local data = textutils.unserialize(dec(_file_data))
      for i = 1, #data do
        local file = fs.open(fs.combine(root, data[i].meta.path), 'w')
        file.writeLine(data[i].data)
        file.close()
      end
    end
  ]])

  file.write('_do_unlarballing(({...})[1])')

  file.flush()
end

local function _se_write_larball(file, data)
  local file_h = fs.open(file, 'w')
  local data = enc(textutils.serialize(data))

  file_h.write('local _file_data = \'')
  file_h.write(data)
  file_h.writeLine('\'')
  _se_append_header(file_h)
  _se_append_extractor(file_h, data)

  file_h.close()
end

local _rl = modules.module 'larballs/self-extracting' {
  text = {
    load = function()
      _G.larball.selar = function(file, dir)
        _se_write_larball(file, _do_larring(dir))

      end
    end,
    unload = function()
      _G.larball.selar = nil
    end
  }
}