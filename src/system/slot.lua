-- slot system

slot = {
  slots = 3,
  keys = {},
  flags_keys = {},
  -- address 60: bitflags (first_run at bit 0, then user flags)
  -- addresses 61-63: available
  flags_addr = 60
}

-- Initialize cartdata with save structure
function slot:init(cart_id, keys, flags_keys)
  cartdata(cart_id or "pico8_bp_v1")
  self.keys = keys or {}
  self.flags_keys = flags_keys or {}

  -- sort keys alphabetically for consistent order
  for i = 1, #self.keys - 1 do
    for j = i + 1, #self.keys do
      if self.keys[j] < self.keys[i] then
        self.keys[i], self.keys[j] = self.keys[j], self.keys[i]
      end
    end
  end

  for i = 1, #self.flags_keys - 1 do
    for j = i + 1, #self.flags_keys do
      if self.flags_keys[j] < self.flags_keys[i] then
        self.flags_keys[i], self.flags_keys[j] = self.flags_keys[j], self.flags_keys[i]
      end
    end
  end
end

-- Save data to a slot
function slot:save(s, data)
  if s < 1 or s > self.slots then return false end

  local base = (s - 1) * 20
  dset(base, 1) -- mark used
  dset(base + 1, stat(92)) -- timestamp

  for i = 1, #self.keys do
    dset(base + i + 1, data[self.keys[i]] or 0)
  end

  return true
end

-- Load data from a slot
function slot:load(s)
  if s < 1 or s > self.slots then return nil end
  if not self:exists(s) then return nil end

  local base = (s - 1) * 20
  local data = {}

  for i = 1, #self.keys do
    data[self.keys[i]] = dget(base + i + 1)
  end

  return data
end

-- Check if slot exists
function slot:exists(s)
  return s >= 1 and s <= self.slots and dget((s - 1) * 20) == 1
end

-- Get slot timestamp
function slot:timestamp(s)
  return self:exists(s) and dget((s - 1) * 20 + 1) or nil
end

-- Delete slot
function slot:delete(s)
  if s < 1 or s > self.slots then return false end
  for i = 0, 19 do
    dset((s - 1) * 20 + i, 0)
  end
  return true
end

-- Save options (flags packed into address 60)
-- bit 0 = initialized flag, bits 1+ = user flags
function slot:save_options(data)
  local packed = 1  -- bit 0 = initialized
  for i = 1, #self.flags_keys do
    if data[self.flags_keys[i]] then
      packed = packed + shl(1, i)
    end
  end
  dset(self.flags_addr, packed)
  return true
end

-- Load options (returns nil if never saved)
function slot:load_options()
  local packed = dget(self.flags_addr)
  -- check initialized bit
  if band(packed, 1) == 0 then
    return nil
  end
  local data = {}
  for i = 1, #self.flags_keys do
    data[self.flags_keys[i]] = band(packed, shl(1, i)) > 0
  end
  return data
end

-- Reset options (clears address 60)
function slot:reset_options()
  dset(self.flags_addr, 0)
end

-- helper
function slot:label(n)
  if slot:exists(n) then
    local data = slot:load(n)
    return 'sLOT '..n..' - wAVE ' .. data.wave
  end
  return 'sLOT '..n..' - eMPTY'
end

-- Menu helpers

-- Create load menu items (loads and switches to game scene)
function slot:load_menu(opts)
  opts = opts or {}
  local items = {}
  for n = 1, self.slots do
    add(items, {
      label = function() return self:label(n) end,
      enabled = function() return self:exists(n) end,
      action = function()
        local data = self:load(n)
        if data then scene:switch(opts.scene or 'game', data) end
        return true
      end
    })
  end
  return items
end

-- Create save menu items (calls provided save function)
function slot:save_menu(save_fn)
  local items = {}
  for n = 1, self.slots do
    add(items, {
      label = function() return self:label(n) end,
      action = function()
        if save_fn then save_fn(n) end
        return true
      end
    })
  end
  return items
end

-- Create delete menu items with confirmation
function slot:delete_menu()
  local items = {}
  for n = 1, self.slots do
    add(items, {
      label = 'sLOT '..n,
      enabled = function() return self:exists(n) end,
      sub_menu = menu:new({
        {label = 'cONFIRM?', action = function() return self:delete(n) end}
      })
    })
  end
  return items
end
