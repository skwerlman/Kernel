
test.manifest = {
    ["desc"] = "verify the kernel base",
    ["important"] = true,
    ["onFail"] = "The kernel is broken.",
    ["shouldFail"] = false,
}

test.run = function(this)
  local t, e = loadfile("boot.lua");

  if t == nil then
    error('syntax error: ' .. e)
  end
end

return test;
