-- bootstraps the module system

local _modules = {}

function module(name)
  return function(data)
    _modules[name] = data
  end
end

function loadmod(name)
  logf('trying to load \'%s\'', name)
  if _modules[name] then
    _modules[name].text.load()
  end
end

function unloadmod(name)
  logf('trying to unload \'%s\'', name)
  if _modules[name] then
    _modules[name].text.unload()
  end
end

function statemod(name, state)
  logf('trying to state \'%s\'', name)

  if _modules[name] then
    _modules[name].text.states[name]()
  end
end

function loadallmods()
  for k, v in pairs(_modules) do
    loadmod(k)
  end
end

function unloadallmods()
  for k, v in pairs(_modules) do
    unloadmod(k)
  end
end

function stateallmods(state)
  for k, v in pairs(_modules) do
    statemod(k, state)
  end
end


return {
  ['module'] = module,
  ['loadmod'] = loadmod,
  ['loadallmods'] = loadallmods,
  ['unloadmod'] = unload,
  ['unloadallmods'] = unloadallmods,
  ['statemod'] = statemod,
  ['stateallmods'] = stateallmods
}
