-- mine scene
-- switch to this scene from gamescene
-- players mine through blocks to find gold

minescene = {}

-- block types
local BLOCK_EMPTY = 0
local BLOCK_DIRT = 1
local BLOCK_STONE = 2
local BLOCK_GOLD = 3

-- block colors
local BLOCK_COLS = {
  [BLOCK_DIRT] = {4, 9},    -- brown, orange highlight
  [BLOCK_STONE] = {5, 6},   -- gray, light gray highlight
  [BLOCK_GOLD] = {9, 10}    -- orange, yellow highlight
}

-- block hp (hits to mine)
local BLOCK_HP = {
  [BLOCK_DIRT] = 1,
  [BLOCK_STONE] = 2,
  [BLOCK_GOLD] = 2
}

function minescene:init(game_ref)
  -- store reference to game scene for gold updates
  self.game = game_ref

  -- bind mine controls fresh
  input:bind({
    [input.button.left] = function() self:move_cursor(-1, 0) end,
    [input.button.right] = function() self:move_cursor(1, 0) end,
    [input.button.up] = function() self:move_cursor(0, -1) end,
    [input.button.down] = function() self:move_cursor(0, 1) end,
    [input.button.x] = function() self:mine_block() end,
    [input.button.o] = function() self:exit_mine() end
  })

  -- mine grid settings
  self.grid_w = 10       -- blocks wide
  self.grid_h = 8        -- blocks tall
  self.block_size = 8    -- pixels per block

  -- grid offset (centered horizontally, near top)
  self.grid_x = flr((128 - self.grid_w * self.block_size) / 2)
  self.grid_y = 16

  -- cursor position (grid coords, 1-indexed)
  self.cursor = {x = 1, y = 1}
  self.cursor_bob = 0

  -- generate the mine
  self:generate_mine()

  -- stats
  self.gold_found = 0
  self.blocks_mined = 0
end

function minescene:generate_mine()
  self.grid = {}

  for y = 1, self.grid_h do
    self.grid[y] = {}
    for x = 1, self.grid_w do
      -- first row is always accessible (no blocks above)
      -- determine block type with weighted randomness
      local r = rnd(100)
      if r < 10 then
        -- 10% gold
        self.grid[y][x] = {
          type = BLOCK_GOLD,
          hp = BLOCK_HP[BLOCK_GOLD]
        }
      elseif r < 40 then
        -- 30% stone
        self.grid[y][x] = {
          type = BLOCK_STONE,
          hp = BLOCK_HP[BLOCK_STONE]
        }
      else
        -- 60% dirt
        self.grid[y][x] = {
          type = BLOCK_DIRT,
          hp = BLOCK_HP[BLOCK_DIRT]
        }
      end
    end
  end
end

function minescene:move_cursor(dx, dy)
  local nx = self.cursor.x + dx
  local ny = self.cursor.y + dy

  -- clamp to grid bounds
  nx = mid(1, nx, self.grid_w)
  ny = mid(1, ny, self.grid_h)

  self.cursor.x = nx
  self.cursor.y = ny
  sfx(2, 3)
end

function minescene:is_mineable(x, y)
  -- block must exist
  local block = self.grid[y][x]
  if not block or block.type == BLOCK_EMPTY then
    return false
  end

  -- first row is always mineable
  if y == 1 then
    return true
  end

  -- block is mineable if any adjacent block (above, left, right, below) is empty
  local above = self.grid[y - 1][x]
  if above and above.type == BLOCK_EMPTY then
    return true
  end

  -- check left
  if x > 1 then
    local left = self.grid[y][x - 1]
    if left and left.type == BLOCK_EMPTY then
      return true
    end
  end

  -- check right
  if x < self.grid_w then
    local right = self.grid[y][x + 1]
    if right and right.type == BLOCK_EMPTY then
      return true
    end
  end

  -- check below
  if y < self.grid_h then
    local below = self.grid[y + 1][x]
    if below and below.type == BLOCK_EMPTY then
      return true
    end
  end

  return false
end

function minescene:mine_block()
  local x, y = self.cursor.x, self.cursor.y
  local block = self.grid[y][x]

  -- check if block exists and is mineable
  if not block or block.type == BLOCK_EMPTY then
    -- nothing to mine
    -- sfx(3, 3)  -- error sound
    return
  end

  if not self:is_mineable(x, y) then
    -- blocked - can't mine yet
    -- sfx(3, 3)  -- error sound
    return
  end

  -- reduce block hp
  block.hp -= 1
  sfx(5, 3)  -- hit sound

  if block.hp <= 0 then
    -- block destroyed
    local was_gold = block.type == BLOCK_GOLD

    block.type = BLOCK_EMPTY
    block.hp = 0
    self.blocks_mined += 1

    if was_gold then
      -- found gold! add to player's total
      local wave = self.game.wave or 1

      local min_gold = 5 + wave
      local max_bonus = 5 + wave * 2

      local gold_amount = min_gold + flr(rnd(max_bonus))

      self.gold_found += gold_amount

      if self.game and self.game.gold then
        self.game.gold:add(gold_amount)
      end

      sfx(6, 3)  -- gold sound!
    end
  end
end

function minescene:exit_mine()
  -- switch back to game scene with current state
  local gm, ge = self.game.gold:pack()
  scene:switch('game', {
    hp = self.game.player.hp,
    max_hp = self.game.player.max_hp,
    atk = self.game.player.atk,
    armor = self.game.player.armor,
    spd = self.game.player.spd,
    wave = self.game.wave,
    gold_m = gm,
    gold_e = ge,
    miners = self.game.miners
  })
end

function minescene:update()
  -- cursor bob animation
  self.cursor_bob = sin(time() * 4) * 2
end

function minescene:draw()
  -- dim overlay
  rectfill(0, 0, 127, 127, 0)

  -- draw grid background
  local gx, gy = self.grid_x, self.grid_y
  local gw = self.grid_w * self.block_size
  local gh = self.grid_h * self.block_size
  rectfill(gx - 1, gy - 1, gx + gw, gy + gh, 1)
  rect(gx - 2, gy - 2, gx + gw + 1, gy + gh + 1, 5)

  -- draw blocks
  for y = 1, self.grid_h do
    for x = 1, self.grid_w do
      local block = self.grid[y][x]
      local px = gx + (x - 1) * self.block_size
      local py = gy + (y - 1) * self.block_size

      if block.type != BLOCK_EMPTY then
        local cols = BLOCK_COLS[block.type]
        local mineable = self:is_mineable(x, y)

        -- main block
        rectfill(px, py, px + self.block_size - 1, py + self.block_size - 1, cols[1])

        -- highlight (top-left)
        line(px, py, px + self.block_size - 2, py, cols[2])
        line(px, py, px, py + self.block_size - 2, cols[2])

        -- show damage cracks
        if block.hp < BLOCK_HP[block.type] then
          pset(px + 2, py + 2, 0)
          pset(px + 5, py + 4, 0)
          pset(px + 3, py + 5, 0)
        end

        -- dim non-mineable blocks
        if not mineable then
          for py2 = py, py + self.block_size - 1, 2 do
            for px2 = px + (py2 % 2), px + self.block_size - 1, 2 do
              pset(px2, py2, 1)
            end
          end
        end
      end
    end
  end

  -- draw cursor
  local cx = gx + (self.cursor.x - 1) * self.block_size
  local cy = gy + (self.cursor.y - 1) * self.block_size + self.cursor_bob

  -- cursor outline (animated)
  local cc = self:is_mineable(self.cursor.x, self.cursor.y) and 11 or 8
  rect(cx - 1, cy - 1, cx + self.block_size, cy + self.block_size, cc)

  -- stats
  local stat_y = gy + gh + 8
  print("gOLD mINED: " .. self.gold_found, gx, stat_y, 10)

  -- controls hint
  print("❎ mINE  🅾️ eXIT", 2, 120, 6)
end
