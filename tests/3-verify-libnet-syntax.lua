
test.manifest = {
    ["desc"] = "verify libnet syntax",
    ["important"] = true,
    ["onFail"] = "libnet support will not work :(",
    ["shouldFail"] = false,
}

test.run = function(this)
  loadfile("core/lib/libnet.lua")
end

return test;
