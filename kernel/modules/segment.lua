local function makeSeg(space, stack)
  local ret = {
    ["__kSpaceRest"] = space,
    ["__kID"]        = tostring(math.random()),
    ["__kStack"] = stack
  }

  setmetatable(ret, {
    ["__index"] = function(tab, key)
      if tab["__kStack"] and type(tab[key]) == 'function' then
        table.insert(tab["__kStack"], tab[key])
      end
    end,
    ["__newindex"] = function(tab, key, val)
      if tab["__kSpaceRest"] ~= nil then
        tab["__kSpaceRest"] = tab["__kSpaceRest"] - 1
        if tab["_kSpaceRest"] ~= 0 then
          rawset(tab, key, val)
        end
      end
    end
  })

  return ret
end


local _segments = modules.module "memseg" {
  ["text"] = {
    ["load"] = function()
      _G.memory = {
        ["makeSeg"] = makeSeg
      }
    end,
    ["unload"] = function()
      _G.memory = nil
    end
  }
}
