-- app manager

app = {
  name = nil,
  title = nil,
  defaults = {},
  flags_defaults = {}
}

function app:init(config)
  self.name = config.name or "pico8_boilerplate"
  self.defaults = config.defaults or {}
  self.flags_defaults = config.flags or {}

  -- extract keys from defaults for slot system
  local keys = {}
  for k in pairs(self.defaults) do
    add(keys, k)
  end

  -- extract flags keys (boolean values)
  local flags_keys = {}
  for k in pairs(self.flags_defaults) do
    add(flags_keys, k)
  end

  -- initialize slot system
  slot:init(self.name, keys, flags_keys)
end

function app:save(slot_num, data)
  return slot:save(slot_num, data)
end

function app:load(slot_num)
  return slot:load(slot_num)
end

function app:save_options(data)
  return slot:save_options(data)
end

function app:load_options()
  return slot:load_options()
end

function app:copy_defaults()
  local copy = {}
  for k, v in pairs(self.defaults) do
    copy[k] = v
  end
  return copy
end

function app:copy_flags_defaults()
  local copy = {}
  for k, v in pairs(self.flags_defaults) do
    copy[k] = v
  end
  return copy
end
