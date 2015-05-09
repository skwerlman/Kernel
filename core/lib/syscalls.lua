return {
  ["sys_print"] = function(...)
    os.queueEvent('syscall_return', print(...))
  end
}
