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
      env.threading = {
        ["this"] = getfenv(2).threading.this:spawnSubprocess(tostring(fn))
      }
    else
      env.threading = {
        ["this"] = threading.scheduler:spawnSubprocess(tostring(fn))
      }
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

local function doFindMain(fnc)
  local env = {}
  setmetatable(env, {["__index"] = _G})

  setfenv(fnc, env)
  pcall(fnc)

  if not env.main or not type(env.main) == 'function' then
    error('no public main function', 2)
  else
    return env.main
  end
end

return function(file, ...)
  doExec(file, doFindMain(doLoad(file)), ...)
end
