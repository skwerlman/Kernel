function _G.class(base, init)
  local c = {}    -- a new class instance
  if not init and type(base) == 'function' then
    init = base
    base = nil
  elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
    for i,v in pairs(base) do
      c[i] = v
    end
    c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c
  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__cosumed = {}
  mt.__consumed.mixins = {}
  mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    if init then
      init(obj,...)
    else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
        base.init(obj, ...)
      end
    end
    return obj
  end

  c.init = init
  c.isSubclassOf = function(self, klass)
    local m = getmetatable(self)
    while m do
      if m == klass then return true end
      m = m._base
    end
    return false
  end

  function c:equals (otherObject)
    if not otherObject:isSubclassOf(self) then
      return false
    else
      for i = 1, #otherObject do
        if not otherObject[i] == self[i] then
          return false
        end
      end
    end
    return true
  end

  function c:clone ()
    return c
  end

  function c:toString ()
    local mt = getmetatable(self)
    if mt.__tostring then
      return mt.__tostring()
    end
    return tostring(self)
  end

  function c:include ( mixin )
    if getmetatable(mixin).__name then
      table.insert(getmetatable(self).__consumed, getmetatable(mixin).__name)
    end

    table.insert(getmetatable(self).__consumed.mixins, mixin)

    for k,v in pairs(mixin) do
      if k == 'init' then else
        self[k] = mixin[k]
      end
    end
  end

  function c:respondsToSelector( selector )
    return self[selector] and type(self[selector]) == 'function'
  end

  function c:includes ( name )
    for k, v in pairs(getmetatable(self).__consumed)
      if v == name then return v end
    end

    return false, 'No mathes'
  end

  setmetatable(c, mt)
  return c
end
