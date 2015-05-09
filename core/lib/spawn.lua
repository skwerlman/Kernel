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

return function(fileOrFunc)
  if threading then
    if type(fileOrFunc) == 'string' then
      if getfenv(2).threading and getfenv(2).threading.this then
        return getfenv(2).threading.this:spawnThread(doFindMain(loadfile(fileOrFunc)), fileOrFunc)
      else
        return threading.scheduler:spawnThread(doFindMain(loadfile(fileOrFunc)), fileOrFunc)
      end
    end
  elseif type(fileOrFunc) == 'function' then
    if getfenv(2).threading and getfenv(2).threading.this then
      return getfenv(2).threading.this:spawnThread(fileOrFunc, fileOrFunc)
    else
      return threading.scheduler:spawnThread(fileOrFunc, fileOrFunc)
    end
  end
end
