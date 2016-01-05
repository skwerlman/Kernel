
test.manifest = {
		["desc"] = "verify libnet syntax",
		["important"] = true,
		["onFail"] = "libnet support will not work :(",
		["shouldFail"] = false,
}

test.run = function(this)
	local t, e = loadfile("core/lib/libnet.lua")

	if t == nil then
		error('syntax error: ' .. e)
	end
end

return test;
