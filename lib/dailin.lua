_G.dailin    = {}
local _dlenv = dailin

setmetatable(_dlenv, {
  ["__index"] = _G
})

function _dlenv.dlexp(nam, fun)
  if not _dlenv.exps then
    _dlenv.exps = {
      [nam] = fun
    }
  elseif _dlenv.exps then
    _dlenv.exps[nam] = fun
  end
end

function _dlenv.dlspc(tab)
  if not _dlenv.exps then _dlenv.exps = tab else
    for k, v in pairs(tab) do
      _dlenv.exps[k] = v
    end
  end
end


local function _dlextfns(func)
  local env = {}
  local ret = {}
  setmetatable(env, {
    ["__index"] = _dlenv,
    ["__newindex"] = function(t,k,v)
      if type(v) == 'function' then
        ret[k] = v
      end

      rawset(t,k,v)
    end
  })

  setfenv(func, env)
  pcall(func)

  return env.exps or ret
end

function dailin.dlopen(file)
  local x, err = loadfile(file)
  if not x then printError(err) end

  return _dlextfns(x)
end

if dlspc then
  dlspc(dailin)
end
