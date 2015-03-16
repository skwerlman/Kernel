-- bootstraps the module system

local _modules = {}

local function module(name)
  return function(data)
    _modules[name] = data
  end
end

local function loadModule(name)
  logf('Trying to load \'%s\'', name)
  if _modules[name] then
    _modules[name].text.load()
  end
end

local function unloadModule(name)
  logf('Trying to unload \'%s\'', name)
  if _modules[name] then
    _modules[name].text.unload()
  end
end

local function stateModule(name, state)
  logf('Trying to state \'%s\': %s', name, state)

  if _modules[name] and _modules[name].text.states
      and _modules[name].text.states[state] then
    _modules[name].text.states[name]()
  end
end

local function loadAllModules()
  for k, v in pairs(_modules) do
    loadModule(k)
  end
end

local function unloadAllModules()
  for k, v in pairs(_modules) do
    unloadModule(k)
  end
end

local function stateAllModules(state)
  for k, v in pairs(_modules) do
    stateModule(k, state)
  end
end

local function reloadModule(mod)
  unloadModule(mod)
  loadModule(mod)
end

local function reloadAllModules()
  for k, v in pairs(_modules) do
    reloadModule(k)
  end
end

return {
  ['module'] = module,
  ['loadModule'] = loadModule,
  ['loadAllModules'] = loadAllModules,
  ['unloadModule'] = unloadModule,
  ['unloadallmods'] = unloadallmods,
  ['stateModule'] = stateModule,
  ['stateAllModules'] = stateAllModules,
  ['reloadModule'] = reloadModule,
  ['reloadAllModules'] = reloadAllModules
}
