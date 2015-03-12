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

local function _write_larball(file, data)
  local file_h = fs.open(file, 'w')
  file_h.writeLine(enc(textutils.serialize(data)))
  file_h.close()
end

local function _do_unlarring(root, data)
  for i = 1, #data do
    local file = fs.open(fs.combine(root, data[i].meta.path), 'w')
    file.writeLine(data[i].data)
    file.close()
  end

end

local function _do_unlarballing(rootdir, file)
  local data = fs.open(file, 'r')
  local tab = textutils.unserialize(dec(data.readAll()))
  data.close()


  _do_unlarring(rootdir, tab)
end

local _lar = module 'larballs' {
  text = {
    load = function()
      _G.larball = {
        ['lar_file'] = function(file, dir)
          fs.delete(file)
          local x = fs.open(file, 'w')
          x.writeLine(enc(textutils.serialize(_do_larring(dir))))
          x.close()

        end,
        ['unlar_file'] = _do_unlarballing,
        ['root_unlar'] = function(file)
          _do_unlarballing('/', file)
        end,
        ['do_dirlar'] = _do_larring,
      }
    end,
    unload = function()
      _G.larball = nil
    end
  }
}
