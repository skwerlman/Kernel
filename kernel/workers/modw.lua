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

--logf('module worker starting')
local list = (listAll( fs.combine(_G.params.root, '/modules')))

for k, v in pairs(list) do
  if not fs.isDir(v) then
    logf('doing file \'%s\'', v)
    dofile(v)
  end
end

modules.loadAllModules()
