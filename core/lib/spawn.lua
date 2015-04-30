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

return function(file)
  if threading then
    if getfenv(2).threading and getfenv(2).threading.this then
      return getfenv(2).threading.this:spawnThread(doFindMain(loadfile(file)))
    else
      return threading.scheduler:spawnThread(doFindMain(loadfile(file)))
    end
  end
end
