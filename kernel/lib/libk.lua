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

_G.arch = {}

function _G.arch.getComputerType()
  local ret = ""

  if pocket then
    ret = ret .. "pocket-"
  elseif turtle then
    ret = ret .. "turtle-"
  else
    ret = ret .. "computer-"
  end

  if term.isColor and term.isColor() then
    ret = ret .. "color"
  else
    ret = ret .. "regular"
  end

  return ret
end

function _G.arch.getTriplet()
  return arch.getComputerType() .. '-tardix-tabi'
end

function getopt(optstring, ...)
	local opts = { }
	local args = { ... }

	for optc, optv in optstring:gmatch"(%a)(:?)" do
		opts[optc] = { hasarg = optv == ":" }
	end

	return coroutine.wrap(function()
		local yield = coroutine.yield
		local i = 1

		while i <= #args do
			local arg = args[i]

			i = i + 1

			if arg == "--" then
				break
			elseif arg:sub(1, 1) == "-" then
				for j = 2, #arg do
					local opt = arg:sub(j, j)

					if opts[opt] then
						if opts[opt].hasarg then
							if j == #arg then
								if args[i] then
									yield(opt, args[i])
									i = i + 1
								elseif optstring:sub(1, 1) == ":" then
									yield(':', opt)
								else
									yield('?', opt)
								end
							else
								yield(opt, arg:sub(j + 1))
							end

							break
						else
							yield(opt, false)
						end
					else
						yield('?', opt)
					end
				end
			else
				yield(false, arg)
			end
		end

		for i = i, #args do
			yield(false, args[i])
		end
	end)
end
