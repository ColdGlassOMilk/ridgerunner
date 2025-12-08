-- state

state = {}

function state:new(states, initial)
  local s = {
    states = states,
    current = nil,
    prev = nil,
    data = {}
  }
  setmetatable(s, {__index = self})
  if initial then s:switch(initial) end
  return s
end

function state:switch(name, ...)
  if self.current then
    local s = self.states[self.current]
    if s.exit then s:exit(self.data, ...) end
  end

  self.prev = self.current
  self.current = name

  local s = self.states[name]

  -- handle input context switching
  if s.bindings then
    if self.prev then
      -- switching from another state, pop old context
      input:pop()
    end
    input:push()
    input:bind(s.bindings)
  elseif self.prev and self.states[self.prev].bindings then
    -- new state has no bindings, but old state did
    input:pop()
  end

  if s.init then s:init(self.data, ...) end

  if message_bus then
    message_bus:emit("state_changed", {
      mgr=self,
      from=self.prev,
      to=name
    })
  end
end

function state:update()
  local s = self.states[self.current]
  if s.update then s:update(self.data) end
end

function state:draw()
  local s = self.states[self.current]
  if s.draw then s:draw(self.data) end
end
