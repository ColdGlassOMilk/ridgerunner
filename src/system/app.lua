-- app manager

app = {
  name = nil,
  defaults = {},
  flags_defaults = {}
}

function app:init(config)
  self.name = config.name
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
