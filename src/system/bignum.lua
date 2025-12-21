-- bignum system for large numbers
-- stores as mantissa + exponent (scientific notation)
-- e.g., 32000 = 3.2 * 10^4 = {m=3.2, e=4}

bignum = {}
bignum.__index = bignum

-- max mantissa before we normalize (keep under pico-8 limits)
local MAX_M = 1000
local MIN_M = 1

-- create a new bignum from a regular number, table, or string
function bignum:new(val)
  local b = {m = 0, e = 0}
  setmetatable(b, self)

  if type(val) == "table" and val.m then
    -- copy from another bignum
    b.m = val.m
    b.e = val.e
  elseif type(val) == "string" then
    -- parse string for large numbers that would overflow
    b:from_str(val)
  elseif type(val) == "number" then
    b:set(val)
  end

  return b
end

-- parse a string like "100000000000" or "1e11" or "1.5e6"
function bignum:from_str(s)
  -- check for scientific notation (e.g., "1e11" or "1.5e6")
  local m_str, e_str = s:match("([%d%.]+)e(%d+)")
  if m_str then
    self.m = tonum(m_str)
    self.e = tonum(e_str)
    self:normalize()
    return self
  end

  -- regular number string - count digits
  local len = #s
  if len <= 4 then
    -- small enough to parse directly
    self.m = tonum(s)
    self.e = 0
  else
    -- take first few digits as mantissa
    local decimal_pos = 3  -- put decimal after 3rd digit
    local int_part = sub(s, 1, decimal_pos)
    local frac_part = sub(s, decimal_pos + 1, decimal_pos + 2)
    self.m = tonum(int_part .. "." .. frac_part)
    self.e = len - decimal_pos
  end
  self:normalize()
  return self
end

-- set from a regular number
function bignum:set(n)
  if n == 0 then
    self.m = 0
    self.e = 0
    return self
  end

  self.m = n
  self.e = 0
  self:normalize()
  return self
end

-- normalize: keep mantissa in range [1, 1000)
function bignum:normalize()
  if self.m == 0 then
    self.e = 0
    return self
  end

  -- handle negative (shouldn't happen for costs, but just in case)
  local sign = 1
  if self.m < 0 then
    sign = -1
    self.m = -self.m
  end

  -- scale down if too large (use 999.99 to avoid edge cases)
  while self.m >= 999.99 do
    self.m = self.m * 0.1
    self.e = self.e + 1
  end

  -- scale up if too small
  while self.m < MIN_M and self.m > 0 do
    self.m = self.m * 10
    self.e = self.e - 1
  end

  self.m = self.m * sign
  return self
end

-- convert to regular number (may overflow for large values!)
function bignum:tonum()
  if self.e <= 4 then
    return self.m * (10 ^ self.e)
  end
  -- too large, return max safe value
  return 32767
end

-- check if this bignum can safely be a regular number
function bignum:is_small()
  return self.e <= 4 and self:tonum() <= 32767
end

-- add another bignum or number
function bignum:add(other)
  if type(other) == "number" then
    other = bignum:new(other)
  end

  -- align exponents by adjusting mantissas safely
  local diff = self.e - other.e

  if diff >= 6 then
    -- other is negligible
    return self
  elseif diff <= -6 then
    -- self is negligible
    self.m = other.m
    self.e = other.e
    return self
  end

  -- bring both to the same exponent (the larger one)
  local self_m, other_m, result_e

  if diff > 0 then
    -- self has larger exponent, scale other down
    result_e = self.e
    self_m = self.m
    other_m = other.m
    for i = 1, diff do
      other_m = other_m * 0.1
    end
  elseif diff < 0 then
    -- other has larger exponent, scale self down
    result_e = other.e
    other_m = other.m
    self_m = self.m
    for i = 1, -diff do
      self_m = self_m * 0.1
    end
  else
    -- same exponent
    result_e = self.e
    self_m = self.m
    other_m = other.m
  end

  self.m = self_m + other_m
  self.e = result_e
  self:normalize()
  return self
end

-- subtract another bignum or number
function bignum:sub(other)
  if type(other) == "number" then
    other = bignum:new(other)
  end

  -- same as add but negate
  local neg = bignum:new({m = -other.m, e = other.e})
  return self:add(neg)
end

-- multiply by a number or bignum
function bignum:mul(other)
  if type(other) == "number" then
    self.m = self.m * other
    self:normalize()
    return self
  end

  -- multiply bignums
  self.m = self.m * other.m
  self.e = self.e + other.e
  self:normalize()
  return self
end

-- compare: returns -1, 0, or 1
function bignum:cmp(other)
  if type(other) == "number" then
    other = bignum:new(other)
  end

  -- handle zero cases
  if self.m == 0 and other.m == 0 then return 0 end
  if self.m == 0 then return other.m > 0 and -1 or 1 end
  if other.m == 0 then return self.m > 0 and 1 or -1 end

  -- handle sign differences
  if self.m < 0 and other.m > 0 then return -1 end
  if self.m > 0 and other.m < 0 then return 1 end

  -- same sign - normalize both to [1, 10) range for fair comparison
  local sign = self.m > 0 and 1 or -1

  local self_m = self.m < 0 and -self.m or self.m
  local self_e = self.e
  while self_m >= 10 do
    self_m = self_m * 0.1
    self_e = self_e + 1
  end
  while self_m < 1 and self_m > 0 do
    self_m = self_m * 10
    self_e = self_e - 1
  end

  local other_m = other.m < 0 and -other.m or other.m
  local other_e = other.e
  while other_m >= 10 do
    other_m = other_m * 0.1
    other_e = other_e + 1
  end
  while other_m < 1 and other_m > 0 do
    other_m = other_m * 10
    other_e = other_e - 1
  end

  -- compare exponents first
  if self_e > other_e then return sign end
  if self_e < other_e then return -sign end

  -- same exponent, compare mantissa
  if self_m > other_m then return sign end
  if self_m < other_m then return -sign end
  return 0
end

function bignum:gte(other)
  return self:cmp(other) >= 0
end

function bignum:lte(other)
  return self:cmp(other) <= 0
end

function bignum:gt(other)
  return self:cmp(other) > 0
end

function bignum:lt(other)
  return self:cmp(other) < 0
end

function bignum:eq(other)
  return self:cmp(other) == 0
end

-- clone this bignum
function bignum:clone()
  return bignum:new({m = self.m, e = self.e})
end

-- format for display
function bignum:tostr()
  -- calculate the "order of magnitude" for display
  -- first normalize temp values to get effective exponent
  local eff_e = self.e
  local temp_m = self.m

  -- handle negative
  local sign = ""
  if temp_m < 0 then
    sign = "-"
    temp_m = -temp_m
  end

  -- normalize to [1, 10)
  while temp_m >= 10 do
    temp_m = temp_m * 0.1
    eff_e = eff_e + 1
  end
  while temp_m < 1 and temp_m > 0 do
    temp_m = temp_m * 10
    eff_e = eff_e - 1
  end

  -- for small numbers (eff_e <= 3 means value < 10000), show as integer
  if eff_e <= 3 and eff_e >= 0 then
    local n = temp_m
    for i = 1, eff_e do
      n = n * 10
    end
    return sign .. tostr(flr(n + 0.5))
  end

  -- use suffix notation: k, m, b, t, etc.
  local suffixes = {"", "k", "m", "b", "t", "q", "Q", "s", "S", "o", "n", "d"}
  local suffix_idx = flr(eff_e / 3) + 1

  if suffix_idx > #suffixes then
    -- really big, use scientific notation
    return sign .. tostr(flr(temp_m * 10) / 10) .. "e" .. tostr(eff_e)
  end

  if suffix_idx < 1 then suffix_idx = 1 end

  -- how many digits before the suffix?
  local remainder = eff_e % 3
  local display = temp_m
  for i = 1, remainder do
    display = display * 10
  end

  -- format nicely
  if display >= 100 then
    return sign .. tostr(flr(display)) .. suffixes[suffix_idx]
  elseif display >= 10 then
    return sign .. tostr(flr(display * 10) / 10) .. suffixes[suffix_idx]
  else
    return sign .. tostr(flr(display * 100) / 100) .. suffixes[suffix_idx]
  end
end

-- for save system: pack into two numbers
function bignum:pack()
  return self.m, self.e
end

-- for save system: unpack from two numbers
function bignum:unpack(m, e)
  self.m = m or 0
  self.e = e or 0
  return self
end
