
test.manifest = {
    ["desc"] = "verify libnet syntax",
    ["important"] = true,
    ["onFail"] = "libnet support will not work :(",
    ["shouldFail"] = false,
}

test.run = function(this)
  local t = loadfile("core/lib/libnet.lua")

  if t == nil then
    error("t is nil, syntax error?")
  end
end

return test;
