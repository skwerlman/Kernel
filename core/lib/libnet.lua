--[[
The MIT License (MIT)

Copyright (c) 2014-2015 the TARDIX team


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Based off of the RFC793 standards, made by the TARDIX Team.

TODO:

  * Finalize the other OSI layers
  * Error checking
  * UDP/TCP (UDP done)
  * make sending different prots not require so much DRY.


  * when you are unsure of a type, always tostring it.
Coding Style:
  * tab = 3 spaces.


Author: Jared Allard <rainbowdashdc@pony.so>
]]--

-- TODO: [ ] port to rewrite

-- bit
local floor = math.floor
local MOD = 2^32

local lshift, rshift -- forward declare

local function rshift(a,disp) -- Lua5.2 insipred
	if disp < 0 then return lshift(a,-disp) end
	return floor(a % MOD / 2^disp)
end

local function lshift(a,disp) -- Lua5.2 inspired
	if disp < 0 then return rshift(a,-disp) end
	return (a * 2^disp) % MOD
end

bit =  {
	-- bit operations
	bnot = bit.bnot,
	band = bit.band,
	bor  = bit.bor,
	bxor = bit.bxor,
	brshift = bit.brshift,
	rshift = rshift,
	lshift = lshift,
}


-- FCS16
local fcs16 = {}

fcs16["table"] = {
[0]=0, 4489, 8978, 12955, 17956, 22445, 25910, 29887,
35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735,
4225, 264, 13203, 8730, 22181, 18220, 30135, 25662,
40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510,
8450, 12427, 528, 5017, 26406, 30383, 17460, 21949,
44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797,
12675, 8202, 4753, 792, 30631, 26158, 21685, 17724,
48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572,
16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011,
52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859,
21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786,
57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634,
25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073,
61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921,
29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848,
65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696,
33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623,
2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999,
38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398,
6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774,
42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685,
10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061,
46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460,
14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836,
50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747,
19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123,
54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522,
23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898,
59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809,
27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185,
63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584,
31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960 }

function fcs16.hash(str) -- Returns FCS16 Hash of @str
    local i
    local l=string.len(str)
    local uFcs16 = 65535
    for i = 1,l do
        uFcs16 = bit.bxor(bit.brshift(uFcs16,8), fcs16["table"][bit.band(bit.bxor(uFcs16, string.byte(str,i)), 255)])
    end
    return  bit.bxor(uFcs16, 65535)
end

--[[
  Why is this here? Because @DemHydraz doesn't believe in globals.
]]
local base64 = {}
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function base64.enc(data)
  return ((data:gsub('.', function(x)
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    return r;
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
local function base64.dec(data)
  data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

-- versions (not in binary)
local tcpver = "101"
local ipv4ver = "100"


-- setup object
local net = {}
logn = {}
logn.msg = {}

-- interface table
net.inf = {}

-- table for types
net.layers = {}
net.layers.transport = {}
net.layers.network = {}
net.layers.data = {}

-- setup each table type
net.layers.transport["tcp"] = true
net.layers.network["ipv4"] = true
net.layers.data["data"] = true
net.layers.data["icmp"] = true

-- network log, mostly for insight on the proto
function logn.write(msg)
  print("libnet: "..msg)
  table.insert(logn.msg, msg)
end

function logn.log(msg)
  table.insert(logn.msg, msg)
end

-- display log
function logn.display()
  for i,v in pairs(logn.msg) do
    print(v)
  end
end

-- use the dev API to get all available modems, then we attempt to register an IP.
-- inorder to do so, we will need a DHCP server to tell us the available APIs.
-- however, you can also set a static IP in which the machine will not need
-- a DHCP server but you will need a subnet connected by a switch.
function net.registerInterface(this, side)
  if type(this) ~= "table" then
    print("not called correctly, use :")
    return false
  end

  local modem = {}

  if side == nil then
    modem = devbus.device.getFirstByRawType("modem");
  else
    -- TODO: check if modem exists.
    modem.name = side
  end

  -- something happened, or some interface wasn't setup correctly
  if modem == false then
    return false
  end

  -- interface table
  -- use null to make sure the entry exists, and is a string
  this.inf[modem.name] = {}
  this.inf[modem.name].ip = "null"
  this.inf[modem.name].gateway = "null"
  this.inf[modem.name].netmask = "null"
  this.inf[modem.name].side = modem.name

  modem.obj = peripheral.wrap(modem.name)
  modem.obj.open(65535)

  logn.write(modem.name .. " state changed to UP")
end

function net.registerInterfaces(this)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  -- detect if returned an object or not
  local f = 0

  for k, v in pairs(devices) do
    if v.type == "modem" then
      -- hotlink to the registerInterface. DRY factor.
      this:registerInterface(v.name)
      f = 1
    end
  end

  if f == 0 then
    return false
  end
end

function net.deregisterInterfaces(this)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  -- detect if returned an object or not
  local f = 0

  for k, v in pairs(devices) do
    if v.type == "modem" then
      -- hotlink to the registerInterface. DRY factor.
      this:deregisterInterface(v.name)
      f = 1
    end
  end

  if f == 0 then
    return false
  end
end

-- drop IPs associated with the interface
function net.deregisterInterface(this, side, detached)
  local modem = {}

  if side == nil then
    modem = devbus.device.getFirstByRawType("modem")
  else
    -- TODO: check if modem exists.
    modem.name = side
  end

  -- remove the inf object
  this.inf[modem.name] = nil

  logn.write(modem.name .. " state changed to DOWN")

  if detached ~= false then
    modem.obj = peripheral.wrap(modem.name)
    modem.obj.closeAll()
  end
end

--[[
    Create a data packet and broadcast it onto the network

    @param {string} ip - IP to send to
    @param {string} side - modem location to broadcast over
    @param {string} msg - string to send

    @return {boolean} success or failure
]]
function net.sendData(this, ip, side, msg, channel)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  if channel == nil then
    -- default "port"
    channel = 65535
  end

  -- failsafe checks
  if tostring(this.inf[side]) == nil then
    error("interface isn't registered")
    return false
  elseif this.inf[side].ip == "null" then
    error("no ip assigned")
    return false
  elseif ip == nil then
    error("ip param missing")
    return false
  elseif side == nil then
    error("inf side param missing")
    return false
  elseif msg == nil then
    error("msg param missing")
    return false
  end

  -- body layer is the data layer.
  local body = "layer:data" ..
    ",data:" .. base64.encode(tostring(msg))

  -- [-] TODO: Implement the ICMP layer.
  -- [ ] TODO: have tcp checksum all of it's layers.
  -- [ ] TODO: create a TCP checksum for it's actual header.

  -- TCP Layer
  local tcp = "layer:tcp" ..
    ",version:" .. tcpver ..
    ",dest:" .. tostring(channel) ..
    ",source:" .. tostring(channel) ..
    ",ack:" .. tostring(0) .. -- todo
    ",fin:" .. tostring(0) .. -- todo as well
    ",seg:0" ..
    ",checksum:" .. fcs16.hash(body) ..
    ",;"

  -- IPv4 Layer
  local ipv4 = "layer:ipv4" ..
    ",version:" .. ipv4ver ..
    ",tl:10000" ..
    ",id:" .. net:genIPv4ID() ..
    ",flag:1" ..  -- don't fragment (yet)
    ",source:" .. tostring(this.inf[side].ip) ..
    ",dest:" .. tostring(ip)

  -- IPv4 checksum
  ipv4 = ipv4 ..
    ",checksum:" .. fcs16.hash(ipv4) ..
    ",;"

  local header = "#" .. tcp .. ipv4 .. "#" -- encasp it into the header field,

  -- form the packet
  local packet = header..body

  -- silently log the packet data
  logn.log(packet)

  -- broadcast the data to every machine on the network.
  local mod = peripheral.wrap(side)

  -- broadcast on the rednet channel
  mod.transmit(65535, 65535, packet)

  return true
end

--[[
  broadcast a ICMP message

  :D
]]
function net.sendicmp(this, ip, side, icmptype, icmpcode)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  if channel == nil then
    -- default "port"
    channel = 65535
  end

  -- failsafe checks
  if tostring(this.inf[side]) == nil then
    error("interface isn't registered")
    return false
  elseif this.inf[side].ip == "null" then
    error("no ip assigned")
    return false
  end

  -- body layer is the data layer.
  local body = "layer:icmp" ..
    ",type:" .. tostring(icmptype) ..
    ",code:" .. tostring(icmpcode)

  body = body ..",checksum:" .. fcs16.hash(body)

  -- TCP Layer
  local tcp = "layer:tcp" ..
    ",version:" .. tcpver ..
    ",dest:" .. tostring(channel) ..
    ",source:" .. tostring(channel) ..
    ",ack:" .. tostring(0) .. -- todo
    ",fin:" .. tostring(0) .. -- todo as well
    ",seg:0" ..
    ",checksum:" .. fcs16.hash(body) ..
    ",;"

  -- IPv4 Layer
  local ipv4 = "layer:ipv4" ..
    ",version:" .. ipv4ver ..
    ",tl:10000" ..
    ",id:" .. net:genIPv4ID() ..
    ",flag:1" ..  -- don't fragment (yet)
    ",source:" .. tostring(this.inf[side].ip) ..
    ",dest:" .. tostring(ip)

  -- IPv4 checksum
  ipv4 = ipv4 ..
    ",checksum:" .. fcs16.hash(ipv4) ..
    ",;"

  local header = "#" .. tcp .. ipv4 .. "#" -- encasp it into the header field,

  -- form the packet
  local packet = header..body

  -- silently log the packet data
  logn.log(packet)

  -- broadcast the data to every machine on the network.
  local mod = peripheral.wrap(side)

  -- broadcast on the rednet channel
  mod.transmit(65535, 65535, packet)

  return true
end

function net.genIPv4ID()
  return 000000 -- placeholder
end

--[[
  Packet reciever, loops over net.receive()

  NOTE: This blocks.

  @return false on failure
]]
function net.d(this)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  -- start the rednet reciever daemon.
  while true do
    id, data = rednet.receive()

    this:receive(id, data)
  end
end


--[[
  Attempt to receive data back.

  @return data
]]
function net.receive(this, sid, message)
  if type(this) ~= "table" then
    print("not called correctly, use :")
    return false
  end

  -- [x] TODO: implement layer parsing, with fallsafe if corrupt
  -- [x] TODO: (re)Implement TCP libnet specs.
  -- [x] TODO: (re)Implement the new IPv4 specs.
  -- [ ] TODO: Implement the new ICMP specs.

  local l = this:parseLayers(message)

  -- build our objects
  local tcp  = l.tcp
  local ipv4 = l.ipv4
  local data = l.data
  local icmp = l.icmp

  local fData = nil

  -- parse it!
  if tostring(this.inf[sid]) == nil then
    logn.write("CRIT: got packet, but interface ! exist")
  elseif ipv4.dest ~= tostring(this.inf[sid].ip) then
    logn.write("dropping; from " .. ipv4.source .. ": ERRNOTOURS ["..ipv4.dest.."] ")
  elseif data.type == "data" then
    fData = data.data
    logn.write("recieved: ".. tostring(fData) .. " from " .. ipv4.source)
  elseif data.type == "icmp" then
    icmpcode = tostring(icmp.code)
    icmptype = tostring(icmp.type)

    logn.write("recv icmp type " .. icmptype .. " code " .. icmpcode ..
      " from " .. ipv4.source)

    -- handle the ICMP.

    if this:doICMP(icmptype, icmpcode, l, sid) == false then
      logn.write("error: icmp couldn't be handled: ERRNOTRECOGNIZED")
    end
  end

  return fData;
end

function net.doICMP(this, icmptype, icmpcode, req, side)
  if icmptype == "0" then
    if icmpcode == "0" then
      return true -- do nothing per specs
    elseif icmpcode == "1" then
      this:sendicmp(req.ipv4.source, side, 0, 0)
      logn.write("responded to a ping")
    elseif icmpcode == "2" then
      this:sendicmp(req.ipv4.source, side, 0, 3)
      logn.write("responded to a tracert")
    elseif icmpcode == "3" then
      logn.write("receieved a traceroute resp.")
    else
      logn.write("icmp: [1] not recognized code")
      return false
    end
  else
    logn.write("icmp: not recognized type")
    return false
  end

  -- by default, return true
  return true
end

function net.routerdoICMP(this, icmptype, icmpcode, req, side)
  if icmptype == "0" then
    if icmpcode == "0" then
      return true -- do nothing per specs
    elseif icmpcode == "2" then -- respond to a traceroute
      net:sendicmp(req.ipv4.source, side, 0, 3)
      logn.write("responded to a ping")
    else
      logn.write("icmp: [0] not recognized code")
      return false
    end
  else
    logn.write("icmp: not recognized type")
    return false
  end

  -- by default, return true
  return true
end

function net.parseLayers(this, message)
  if type(this) ~= "table" then
    print("not called correctly, use :")
    return false
  end

  -- scope.
  local icmp = {}
  local tcp  = {}
  local ipv4 = {}
  local data = {}

  -- pass through each layer.
  for i,v in pairs(string.split(message, ";")) do
    -- remove the hash(es)
    v = string.gsub(v, "#", "")
    -- log the data.
    logn.log(v)

    -- parse the layer type
    local layer = tostring(string.match(v, "layer:([a-z0-9]+),"))
    logn.log("layer [".. tostring(i) .. "] protocol is "..layer)

    -- check layer order
    if i == 1 then
      if this.layers.transport[layer] ~= true then
        logn.write("1st layer is not a transport layer?")
        return false
      end
    elseif i == 2 then
      if this.layers.network[layer] ~= true then
        logn.write("2nd layer is not a network layer?")
        return false
      end
    elseif i == 3 then
      if this.layers.data[layer] ~= true then
        logn.write("3rd layer is not a data layer?")
        return false
      end
    end

    -- check layer type
    if layer == "tcp" then
      logn.write("parsing layer tcp")

      -- parse the TCP data
      tcp.version = tostring(string.match(v, "version:([0-9]+),"))
      tcp.seg = tostring(string.match(v, "seg:([0-9]+),"))
      tcp.destP = tostring(string.match(v, "dest:([0-9]+),"))
      tcp.srcP = tostring(string.match(v, "source:([0-9]+),"))
      tcp.ack = tostring(string.match(v, "ack:([0-9]+),"))
      tcp.fin = tostring(string.match(v, "fin:([0-9]+),"))
      tcp.checksum = tostring(string.match(v, "checksum:([0-9]+),"))
    elseif layer == "ipv4" then
      logn.write("parsing layer ipv4")

      -- parse the ipv4 layer
      ipv4.version = tostring(string.match(v, "version:([0-9]+),"))
      ipv4.ttl = tostring(string.match(v, "ttl:([0-9]+),"))
      ipv4.id = tostring(string.match(v, "id:([0-9]+),"))
      ipv4.flag = tostring(string.match(v, "flag:([0-9]+),"))
      ipv4.dest = tostring(string.match(v, "dest:([0-9.]+),"))
      ipv4.source = tostring(string.match(v, "source:([0-9.]+),"))
      ipv4.protocol = tostring(string.match(v, "protocol:([0-9a-zA-Z]+),"))
      ipv4.checksum = tostring(string.match(v, "checksum:([0-9]+),"))
    elseif layer == "data" then
      logn.write("parsing layer data")

      -- parse the data layer
      data.data = tostring(string.match(v, "data:([a-zA-Z=]+)"))
      data.data = base64.decode(data.data) -- unmask the data

      data.type = "data"
    elseif layer == "icmp" then
      logn.write("parsing layer icmp")
      icmp.type = tostring(string.match(v, "type:([0-9]+),"))
      icmp.code = tostring(string.match(v, "code:([0-9]+),"))
      icmp.checksum = tostring(string.match(v, "checksum:([0-9]+)"))

      data.type = "icmp"
    else
      logn.write("unknown layer received")
    end
  end

  -- build the return object
  local layers = {}
  layers.tcp   = tcp
  layers.ipv6  = ipv6
  layers.ipv4  = ipv4
  layers.icmp  = icmp
  layers.data  = data

  -- return the final object
  return layers
end

--[[
  Get all interfaces currently registered

  @return {object} o - table of interface objects
]]
function net.getInterfaces(this)
  if type(this) ~= "table" then
    error("not called correctly, use :")
    return false
  end

  local o = {}

  -- get all registered interfaces
  for i,v in pairs(this.inf) do
    table.insert(o, v)
  end

  -- return the object
  return o
end

--[[
  explodes an IP into a table per digit.
]]
function net.ipToTable(ip)
  return string.split(ip, ".")
end

--[[
  Forward a packet across interfaces.

  @return nil
]]
function net.forward(this, msg, subnet, side)
  -- [-] TODO: Sort out interfaces and broadcast accordingly.

  local inf = this.inf

  logn.write("subnet for packet: "..subnet)

  -- sort out each registered interface.
  for k, v in pairs(inf) do
    -- TODO: Optimize this to determine if we have another subnet setup.
    if tostring(v.subnet) ~= "nil" then
      local submj = tostring(string.match(v.subnet, "^([0-9]+.[0-9]+.[0-9]+)"))
      if subnet == submj then
        logn.write("forwarding packet over ".. v.side)

        local m = peripheral.wrap(v.side)
        m.open(65535)
        m.transmit(65535, 65535, msg)

        logn.write("done")

        return
      else
        logn.write("packet subnet != inf " .. v.side .." subnet, skip")
      end
    elseif v.side == side then
      logn.write("origin side, skipping")
    else
      logn.write("forwarding packet over ".. v.side)

      local m = peripheral.wrap(v.side)
      m.open(65535)
      m.transmit(65535, 65535, msg)

      logn.write("done")
    end
  end
end

--[[
  Parse packets and determine where they should go without causing net clutter.
]]
function net.handoff(this, sid, message)
  -- parse the message layers
  local l = this:parseLayers(message)

  -- build our objects
  local tcp  = l.tcp
  local ipv4 = l.ipv4
  local data = l.data
  local icmp = l.icmp

  -- define scope
  local pdata = nil
  local isSub = false
  local subnet = nil

  -- Determine if in or out
  if tostring(this.inf[sid].subnet) == "nil" then
    logn.write("error: no subnet configured, !PACKET DROPPED!")
    return false
  else
    logn.write("inspecting packet")

    -- currently only works on xxx.xxx.xxx.<dif> subnets, no xxx.xxx.<dif>.xxx
    subnet = string.match(ipv4.dest, "^([0-9]+.[0-9]+.[0-9]+)")

    -- local subip = string.match(to, ".([0-9]+)$")
    local submj = string.match(this.inf[sid].subnet, "^([0-9]+.[0-9]+.[0-9]+)")

    if subnet == submj then
      logn.write("packet is on subnet")
      isSub = true
    end
  end

  local s = 0

  -- failsafe
  if tostring(this.inf[sid]) == nil then
    logv.write("CRIT: got packet, but interface ! exist")

  -- if it has a subnet, don't broadcast it there.
  -- TODO: broadcast it there if it matchs that network.
  elseif isSub == true then
    logn.write("is on local subnet, don't forward")
    s = 1
  elseif icmp.type ~= nil then -- we handle ICMP differently
    logn.write("received a icmp")
    this:routerdoICMP(tostring(icmp.type), tostring(icmp.code), l, sid)
  end

  -- hacky, but it works for now.
  if s == 0 then
    logn.write("passing onto this:forward")
    this:forward(message, subnet, sid) -- pass the message and it's subnet
  end

  return pdata;
end

return net
