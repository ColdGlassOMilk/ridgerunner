-- input

input = {
  button = {
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    o = 4,
    x = 5,
    hold = {
      left = "hold_0",
      right = "hold_1",
      up = "hold_2",
      down = "hold_3",
      o = "hold_4",
      x = "hold_5"
    }
  },
  -- input has its own subscriber system, separate from message_bus
  listeners = {},
  -- stack of listener contexts for push/pop
  stack = {},
  -- whether input is currently blocked (e.g., by overlay)
  blocked = false
}

-- button id to name lookup
local btn_names = {"left", "right", "up", "down", "o", "x"}

function input:update()
  if self.blocked then return end

  -- handle press events (btnp)
  for id = 0, 5 do
    if btnp(id) then
      self:_emit("press:" .. btn_names[id + 1])
    end
    if btn(id) then
      self:_emit("hold:" .. btn_names[id + 1])
    end
  end
end

-- internal emit to input listeners only
function input:_emit(event_key)
  -- debug: store last emit for inspection
  self.last_emit = event_key
  self.listener_keys = ""
  for k,v in pairs(self.listeners) do
    self.listener_keys = self.listener_keys .. k .. " "
    -- check for match
    if k == event_key then
      self.found_match = event_key
    end
  end

  if not self.listeners[event_key] then
    self.miss = event_key
    return
  end

  self.hit = event_key
  for handler in all(self.listeners[event_key]) do
    handler()
  end
end

-- bind handlers to input events
-- usage:
--   input:bind({
--     [input.button.x] = function() ... end,              -- press
--     [input.button.hold.left] = function() ... end,      -- hold
--   })
function input:bind(context)
  for key, handler in pairs(context) do
    local event_key

    if type(key) == "string" and sub(key, 1, 5) == "hold_" then
      -- it's a hold binding like "hold_0"
      local btn_id = tonum(sub(key, 6))
      event_key = "hold:" .. btn_names[btn_id + 1]
    else
      -- it's a button id, default to press
      event_key = "press:" .. btn_names[key + 1]
    end

    if not self.listeners[event_key] then
      self.listeners[event_key] = {}
    end
    add(self.listeners[event_key], handler)
  end
end

-- push current listeners onto stack and start fresh
function input:push()
  add(self.stack, self.listeners)
  self.listeners = {}
end

-- pop listeners from stack, restoring previous context
function input:pop()
  if #self.stack == 0 then return end
  self.listeners = deli(self.stack)
end

-- clear all listeners (but not the stack)
function input:clr()
  self.listeners = {}
end

-- clear everything including stack
function input:reset()
  self.listeners = {}
  self.stack = {}
  self.blocked = false
end

-- helper for checking button state directly
function input:down(b)
  return btn(b)
end

function input:pressed(b)
  return btnp(b)
end
