-- message bus

message_bus = {
  subscribers = {}
}

function message_bus:subscribe(message_type, callback)
  if not self.subscribers[message_type] then
    self.subscribers[message_type] = {}
  end

  add(self.subscribers[message_type], callback)
end

function message_bus:unsubscribe(message_type, callback)
  if not self.subscribers[message_type] then return end

  del(self.subscribers[message_type], callback)
end

function message_bus:emit(message_type, data)
  if not self.subscribers[message_type] then return end

  for callback in all(self.subscribers[message_type]) do
    callback(data)
  end
end

function message_bus:clr()
  self.subscribers = {}
end
