-- message bus

message_bus = {
  subscribers = {}
}

function message_bus:subscribe(event_type, callback)
  if not self.subscribers[event_type] then
    self.subscribers[event_type] = {}
  end
  add(self.subscribers[event_type], callback)

  -- return unsubscribe function for convenience
  return function()
    self:unsubscribe(event_type, callback)
  end
end

function message_bus:unsubscribe(event_type, callback)
  if not self.subscribers[event_type] then return end
  del(self.subscribers[event_type], callback)
end

function message_bus:emit(event_type, data)
  if not self.subscribers[event_type] then return end

  for callback in all(self.subscribers[event_type]) do
    callback(data)
  end
end

-- clear specific event type
function message_bus:clr(event_type)
  if event_type then
    self.subscribers[event_type] = {}
  else
    self.subscribers = {}
  end
end
