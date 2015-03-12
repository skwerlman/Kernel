local function _doload(id)

  local pid = id:gsub(':', '/')

  if not ends(pid, '.lua') then
    if not fs.exists(pid) then
      pid = pid..'.lua'
    end
  end


  local ret, err = loadfile(pid)
  if not ret then
    error()
  end

  return ret()
end



local _load = modules.module 'load' {
  text = {
    load = function()
      _G.load = _doload
    end,
    unload = function()
      _G.unload = nil
    end
  }
}
