function catch(event, name, ...)
  if event == 'syscall' then
    if _G['tardix_sys_'..name] then
      _G['tardix_sys_'..name](...)
    elseif syscalls['sys_'..name] then
      syscalls['sys_'..name](...)
    end
  end
end
