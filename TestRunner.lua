--[[
  Testing framework designed primarly for the TARDIX Kernel & other subsets.

  Programed in mind for the tardix-ci bot.

  Made by Jared Allard <rainbowdashdc@pony.so>
]]

local version = "1.0"
local cc = false;
local fs;
local manifest;
local test;
local i=0;

-- check if cc or base
if computer == nil then
  print("platform is lua");
  fs = require("lfs");
  fs.list = fs.dir;
  unit="ms"
else
  print("platform is computercraft");
  fs = _G["fs"];
  unit="s"
  cc=true;
end

-- Copy the table.
local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

-- test*s* table
tests={}
tests.failed=0;
tests.succed=0;

-- test table
test = {}
test.print = print;
test.failed = function()
  if manifest ~= nil then
    print(manifest.onFail);
  else
    print("Test Failed.");
    test.status=1;
  end
end
test.log = function(m)
  local print = test.print;
  print("test: "..m)
end

-- sandbox it.
local env = copy(_G);
env.error = function(x)
    print("fail\n reason: '"..x.."'");
    -- print(debug.traceback(x));
    test.status=1;
    tests.failed=tests.failed+1;
end
env.test = test;

for file in fs.list("tests") do
  if file ~= "." and file ~= ".." then
    -- increase index value
    i = i+1;

    -- load the file.
    local o  = loadfile("tests/"..file);

    -- check if it already failed (syntax wise).
    if o == nil then
      test.failed(o);
    else
      setfenv(o, env); -- set the enviroment

      local f = o()
      local m = f.manifest;

      io.write("running test #"..i..": '"..tostring(m.desc).."'...")

      local e = pcall(f:run(), nil)

      if e ~= false then
        env.error(e);
      end

      -- must've succeded.
      if test.status ~= 1 then
        print("success");
        tests.succed = tests.succed+1;
      end
    end
  end
end

print("Tests completed.\n")
print("Stats: ");
print("F: "..tostring(tests.failed))
print("S: "..tostring(tests.succed))
print("T: "..os.clock()..unit.."\n")

if tests.failed ~= 0 then
  print("Some tests failed.");
  print("return code 1.")
  os.exit(1);
else
  print("All tests succeded.");
  print("return code 0");
  os.exit(0);
end
