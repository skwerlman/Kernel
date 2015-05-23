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
]]
local ret = {
  thread = {},
  process = {},
}

function ret.thread:new( f, p )
  local t = {}
  t.tid = string.randomize and string.randomize("xxyy:xxyy-xxxx@xxyy") or math.random()
  t.state = 'running'
  t.environment = setmetatable( {}, { __index = getfenv( 2 ) } )
  if p then
    if t.environment.process then
      t.environment.process.this = p
    else
      t.environment.process = {
        ['this'] = p
      }
    end
  end
  t.filter = nil

  t.raw_environment = setmetatable( {}, {
    __index = function( _, k )
      return t.environment[k]
    end,
    __newindex = function( _, k, v )
      t.environment[k] = v
    end
  } )

  setfenv( f, t.raw_environment )
  t.func = f
  t.co = coroutine.create( f )

  setmetatable( t, {
    __index = self;
    __type = function( self )
      return self:type()
    end;
  } )
  os.queueEvent('thread_construct, ', t.tid)
  return t
end

function ret.thread:stop()
  os.queueEvent('thread_stop', t.tid)
  if self.state ~= 'dead' then
    self.state = 'stopped'
  end
end

function ret.thread:pause()
  os.queueEvent('thread_pause', t.tid)
  if self.state == 'running' then
    self.state = 'paused'
  end
end

function ret.thread:resume()
  os.queueEvent('thread_resume', t.tid)
  if self.state == 'paused' then
    self.state = 'running'
  end
end

function ret.thread:restart()
  os.queueEvent('thread_restart', t.tid)
  self.state = 'running'
  self.co = coroutine.create( self.func )
end

function ret.thread:update( event, ... )
  --os.queueEvent('thread_update', self.tid, {event, ...})
  if self.state ~= 'running' then return true, self.state end -- if not running, don't update
  if self.filter ~= nil and self.filter ~= event then return true, self.filter end -- if filtering an event, don't update

  local ok, data = coroutine.resume( self.co, event, ... )
  if not ok then
    print(data)
    self.state = 'stopped'
    return false, data
  end

  if coroutine.status( self.co ) == 'dead' then
    self.state = 'stopped'
    return true, 'die'
  end

  self.filter = data
  return true, data
end

function ret.thread:type()
  return 'thread'
end

local process = {}

function ret.process:new( name )
  local rID = string.randomize and string.randomize("xxyy:xxyy-xxxx@xxyy") or math.random()
  local p = {}

  p.tid = rID
  p.name = name or rID
  p.children = {}

  setmetatable( p, {
    __index = self;
    __type = function( self )
      return self:type()
    end;
  } )
  os.queueEvent('process_construct', name or rID  )
  return p
end

function ret.process:spawnThread( f, name )
  os.queueEvent('thread_spawn', f, self.tid)
  local t = ret.thread:new( f, self )
  if name then
    t.name = name
  else
    t.name = string.randomize and string.randomize("xxyy:xxyy-xxxx@xxyy") or math.random()
  end
  table.insert( self.children, 1, t )
  return t
end


function ret.process:spawnSubprocess( name )
  local p = ret.process:new( name )
  table.insert( self.children, 1, p )
  os.queueEvent('process_spawn', self.tid, p.tid)
  return p
end

function ret.process:update( event, ... )
  --os.queueEvent('process_update', self.tid, {event, ...})
  for i = #self.children, 1, -1 do
    local ok, data = self.children[i]:update( event, ... )
    if not ok then
      if self.exceptionHandler then
        self:exceptionHandler( self.children[i], data )
      else
        return false, data
      end
    end
    if data == 'die' or self.children[i].state == 'stopped' then
      self.children[i].state = 'dead'
      table.remove( self.children, i )
    end
  end
  return true, #self.children == 0 and 'die'
end

function ret.process:stop()
  os.queueEvent('process_stop', self.tid)
  for i = 1, #self.children do
    self.children[i]:stop()
  end
end

function ret.process:pause()
  os.queueEvent('process_pause', self.tid)
  for i = 1, #self.children do
    self.children[i]:pause()
  end
end

function ret.process:resume()
  os.queueEvent('process_resume', self.tid)
  for i = 1, #self.children do
    self.children[i]:resume()
  end
end

function ret.process:restart()
  os.queueEvent('process_restart', self.tid)
  for i = 1, #self.children do
    self.children[i]:restart()
  end
end

function ret.process:list( deep )
  local t = {}
  for i = #self.children, 1, -1 do
    if self.children[i]:type() == 'process' then
      if deep then
        local c = self.children[i]:list( true )
        c.name = self.children[i].name
        t[#t + 1] = c
      else
        t[#t + 1] = self.children[i]
      end
    elseif self.children[i]:type() == 'thread' then
      t[#t + 1] = self.children[i]
    end
  end
  return t
end

function ret.process:type()
  return 'process'
end

ret.scheduler = ret.process:new('scheduler')

coroutine.fire = os.queueEvent

return ret
