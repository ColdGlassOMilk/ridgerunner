-- slot system

slot = {
  slots = 3,
  keys = {}
}

-- Initialize cartdata with save structure
function slot:init(cart_id, keys)
  cartdata(cart_id or "pico8_bp_v1")
  self.keys = keys or {}
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
