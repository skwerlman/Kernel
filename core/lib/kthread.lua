local kthread = {
  ["hans"] = {}
}

function kthread.addFunctions(tab)
  assert(type(tab) == 'table', 'kthread.addFunctions expects a table of functions')
  for k, v in pairs(tab) do
    print(k)
    assert(type(v) == 'function', 'kthread.addFunctions expects a table of functions')
    table.insert(kthread.hans, v)
  end
end

function kthread.getHandlers()
  return kthread.hans
end

local function doFindFncs(fnc)
  local env = {}
  setmetatable(env, {["__index"] = _G})

  setfenv(fnc, env)
  pcall(fnc)
  local ret = {}
  for k, v in pairs(env) do
    if type(v) == 'function' then
      table.insert(ret, v)
    end
  end
  return ret
end

function kthread.addFile(file)
  local ok, err = loadfile(file)
  if not ok then
    error(err)
  end
  kthread.addFunctions(doFindFncs(ok))
end

return kthread
