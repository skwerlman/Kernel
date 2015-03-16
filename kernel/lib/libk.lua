
function _G.logf(fmt, ...)
  local x = fs.open('/kernel.log', 'a')
  x.write(('[%d] :: ' .. fmt .. '\n'):format(os.clock(), ...))
  x.close()

  if _G.params.nocolor then
    print(('[%d] :: ' .. fmt):format(os.clock(), ...))
  else
    io.write('[')
    term.setTextColor(colors.blue)
    io.write(tostring(math.floor(os.clock())))
    term.setTextColor(colors.white)
    io.write(']')
    term.setTextColor(colors.red)
    io.write(' :: ')
    term.setTextColor(colors.white)

    print((fmt):format(...))
  end
end

function _G.dofiles(data)
  for i = 1, #data do
    if not fs.exists(data[i]) then
      logf('[error] :: %s doesn\'t exist.', data[i])
    elseif fs.isDir(data[i]) then
      logf('[error] :: %s is a directory.', data[i])
    else
      dofile(data[i])
    end
  end
end
