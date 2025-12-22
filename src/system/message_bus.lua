-- message bus

message_bus = {
  channels = {{}} -- channel 0 (default) initialized
}

function message_bus:subscribe(event_type, callback, channel)
  channel = channel or 0
  if not self.channels[channel] then
    self.channels[channel] = {}
  end
  if not self.channels[channel][event_type] then
    self.channels[channel][event_type] = {}
  end
  add(self.channels[channel][event_type], callback)

  return function()
    self:unsubscribe(event_type, callback, channel)
  end
end

function message_bus:unsubscribe(event_type, callback, channel)
  channel = channel or 0
  if not self.channels[channel] or not self.channels[channel][event_type] then return end
  del(self.channels[channel][event_type], callback)
end

function message_bus:emit(event_type, data, channel)
  channel = channel or 0
  if not self.channels[channel] or not self.channels[channel][event_type] then return end

  for callback in all(self.channels[channel][event_type]) do
    callback(data)
  end
end

function message_bus:clr(event_type, channel)
  if channel then
    if event_type then
      if self.channels[channel] then
        self.channels[channel][event_type] = {}
      end
    else
      self.channels[channel] = {}
    end
  else
    self.channels = {{}}
  end
end
