function tabsiz(tab)
  local ret = 1
  for k, v in ipairs(tab) do
    ret = ret + 1
  end

  return ret
end

function alloc(size)
  local ret = {}
  setmetatable(ret, {
    ["__newindex"] = function(t,k,v)
      if size >= tabsiz(t) then
        print('passed')
        rawset(t,k,v)
      else
        error('failed to add \'' ..tostring(k)..'\'. the max size of this table is ' .. tostring(size), 2)
      end
    end
  })

  return ret
end
