
test.manifest = {
    ["desc"] = "verify the kernel base",
    ["important"] = true,
    ["onFail"] = "The kernel is broken.",
    ["shouldFail"] = false,
}

test.run = function(this)
  t = loadfile("boot.lua");

  if t == nil then
    error("boot.lua has a syntax error, t = nil [loadfile]")
  end
end

return test;
