-- input

input = {
  button = {
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    o = 4,
    x = 5
  },
  stack = {},
  subs = {}
}

function input:update()
  if btnp(self.button.up) then
    message_bus:emit('btn:up')
  end
  if btnp(self.button.down) then
    message_bus:emit('btn:down')
  end
  if btnp(self.button.left) then
    message_bus:emit('btn:left')
  end
  if btnp(self.button.right) then
    message_bus:emit('btn:right')
  end
  if btnp(self.button.x) then
    message_bus:emit('btn:x')
  end
  if btnp(self.button.o) then
    message_bus:emit('btn:o')
  end
end

function input:down(b)
  return btn(b)
end

function input:pressed(b)
  return btnp(b)
end

function input:bind(context)
  -- register a context (table of button -> handler pairs)
  for btn, handler in pairs(context) do
    -- convert button constant to event string
    local event = 'btn:'..self:_btn_to_name(btn)
    
    if not self.subs[event] then
      self.subs[event] = {}
    end
    add(self.subs[event], handler)
    message_bus:subscribe(event, handler)
  end
end

function input:_btn_to_name(btn)
  for name, id in pairs(self.button) do
    if id == btn then
      return name
    end
  end
  return 'unknown'
end

function input:push()
  -- save current subscriptions and clear
  add(self.stack, self.subs)
  self.subs = {}
  message_bus:clr()
end

function input:pop()
  -- restore previous subscriptions
  message_bus:clr()
  self.subs = deli(self.stack)
  
  -- re-subscribe all handlers
  for event, handlers in pairs(self.subs) do
    for handler in all(handlers) do
      message_bus:subscribe(event, handler)
    end
  end
end

function input:clr()
  self.subs = {}
  message_bus:clr()
end