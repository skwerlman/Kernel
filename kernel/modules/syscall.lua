local Stack = class( function(self) self.vals = {} end)

function Stack:push(...)
  for k, v in ipairs({...}) do
    table.insert(self.vals, v)
  end
end

function Stack:pop()
  -- get num values from stack
  local num = num or 1

  -- return table
  local entries = {}

  -- get values into entries
  for i = 1, num do
    -- get last entry
    if #self.vals ~= 0 then
      table.insert(entries, self.vals[#self.vals])
      -- remove last value
      table.remove(self.vals)
    else
      break
    end
  end
  -- return unpacked entries
  return unpack(entries)
end

function Stack:len()
  return #self.vals
end


local syscalls = {}

function syscalls.uname(stack)
  local mode = stack:pop()
  if mode then
    if mode == 'a' then
      return ("%s %s (%X-%s) @ %s"):format("TARDIX", "localhost-tardix",
        0xcafebabe, "dirty", "2015-MARCH")
    end
  else
    return false, "No mode specified."
  end
end

function syscalls.makeStack(stack)
  return Stack()
end

function syscalls.exit()
  error(2)
end

function syscall(name)
  local _sysc = {
    ["stack"] = Stack()
  }

  function _sysc:param(...  )
    self.stack:push(...)
    return self
  end

  function _sysc:run()
    if syscalls[name] and type(syscalls[name]) == 'function' then
      return syscalls[name](self.stack)
    end
  end


  return _sysc
end
