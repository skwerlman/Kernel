local function doExec(src, fn, ...)
  local env = {}
  local renv = setmetatable( {}, {
    __index = function( _, k )
      return env[k] and env[k] or getfenv(2)[k]
    end,
    __newindex = function( _, k, v )
      env[k] = v
    end
  } )

  if threading then
    if getfenv(2).threading.this then
      env.threading.this = getfenv(2).threading.this:spawnSubprocess(src)
    elseif threading.scheduler then
      env.threading = threading
      env.threading.this = threading.scheduler:spawnSubprocess(src)
    end
  end

  env._FILE = src

  setfenv(fn, renv)
  local ret, err = pcall(fn, ...)

  if not ret then
    error(err, 2)
  end
end

local function doLoad(fil)
  return loadfile(fil)
end

local function doFindMain(src, fnc)
  local env = {}
  setmetatable(env, {["__index"] = _G})

  setfenv(fnc, env)
  pcall(fnc)

  if not env.main or not type(env.main) == 'function' then
    error('no public main function ' .. src, 2)
  else
    return env.main
  end
end

return function(file, ...)
  doExec(file, doFindMain(file, doLoad(file)), ...)
end
