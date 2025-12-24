-- mine scene

minescene = {}

local BLOCK_EMPTY = 0
local BLOCK_DIRT = 6
local BLOCK_STONE = 7
local BLOCK_GOLD = 8

local BLOCK_HP = {
  [BLOCK_DIRT] = 1,
  [BLOCK_STONE] = 3,
  [BLOCK_GOLD] = 2
}

function minescene:init(game_ref)
  self.game = game_ref

  input:bind({
    [input.button.left] = function() self:move_cursor(-1, 0) end,
    [input.button.right] = function() self:move_cursor(1, 0) end,
    [input.button.up] = function() self:move_cursor(0, -1) end,
    [input.button.down] = function() self:move_cursor(0, 1) end,
    [input.button.x] = function() self:mine_block() end,
    [input.button.o] = function() scene:pop() end
  })

  self.grid_w = 10
  self.grid_h = 8
  self.block_size = 8
  self.grid_x = flr((128 - self.grid_w * self.block_size) / 2)
  self.grid_y = 16
  self.cursor = {x = 1, y = 1}
  self.cursor_bob = 0

  self:generate_mine()

  self.gold_found = bignum:new(0)
  self.blocks_mined = 0
  self.mine_timer = 0
  self.miner_gold = bignum:new(0)
  self.prestige = self.game.player.prestige or 0
end

function minescene:generate_mine()
  self.grid = {}
  for y = 1, self.grid_h do
    self.grid[y] = {}
    for x = 1, self.grid_w do
      local r = rnd(100)
      local t = r < 10 and BLOCK_GOLD or (r < 40 and BLOCK_STONE or BLOCK_DIRT)
      self.grid[y][x] = {type = t, hp = BLOCK_HP[t]}
    end
  end
end

function minescene:move_cursor(dx, dy)
  self.cursor.x = mid(1, self.cursor.x + dx, self.grid_w)
  self.cursor.y = mid(1, self.cursor.y + dy, self.grid_h)
  sfx(2, 3)
end

function minescene:is_mineable(x, y)
  local block = self.grid[y][x]
  if not block or block.type == BLOCK_EMPTY then return false end
  if y == 1 then return true end

  local above = self.grid[y - 1][x]
  if above and above.type == BLOCK_EMPTY then return true end

  if x > 1 then
    local left = self.grid[y][x - 1]
    if left and left.type == BLOCK_EMPTY then return true end
  end

  if x < self.grid_w then
    local right = self.grid[y][x + 1]
    if right and right.type == BLOCK_EMPTY then return true end
  end

  if y < self.grid_h then
    local below = self.grid[y + 1][x]
    if below and below.type == BLOCK_EMPTY then return true end
  end

  return false
end

function minescene:mine_block()
  local x, y = self.cursor.x, self.cursor.y
  local block = self.grid[y][x]

  if not block or block.type == BLOCK_EMPTY then return end
  if not self:is_mineable(x, y) then return end

  block.hp -= 1
  sfx(5, 3)

  if block.hp <= 0 then
    local was_gold = block.type == BLOCK_GOLD
    block.type = BLOCK_EMPTY
    block.hp = 0
    self.blocks_mined += 1

    if was_gold then
      local wave = self.game.wave or 1
      local gold_amount = bignum:new(5 + wave + flr(rnd(5 + wave * 2))):mul2(min(self.prestige, 15))
      self.gold_found:add(gold_amount:clone())
      if self.game and self.game.gold then
        self.game.gold:add(gold_amount)
      end
      sfx(6, 3)
    end
  end
end

function minescene:update()
  self.cursor_bob = sin(time() * 4) * 2

  if self.game.miners > 0 then
    self.mine_timer += 1
    if self.mine_timer >= 30 then
      local amt = bignum:new(self.game.miners * self.game.player.pick_lvl):mul2(min(self.prestige, 15))
      self.game.gold:add(amt:clone())
      self.miner_gold:add(amt)
      self.mine_timer = 0
    end
  end
end

function minescene:draw()
  cls()

  local gx, gy = self.grid_x, self.grid_y
  local gw = self.grid_w * self.block_size
  local gh = self.grid_h * self.block_size
  rectfill(gx - 1, gy - 1, gx + gw, gy + gh, 1)
  rect(gx - 2, gy - 2, gx + gw + 1, gy + gh + 1, 5)

  for y = 1, self.grid_h do
    for x = 1, self.grid_w do
      local block = self.grid[y][x]
      local px = gx + (x - 1) * self.block_size
      local py = gy + (y - 1) * self.block_size

      if block.type != BLOCK_EMPTY then
        spr(block.type, px, py)

        local dmg = BLOCK_HP[block.type] - block.hp
        if dmg >= 1 then
          pset(px + 2, py + 2, 0)
          pset(px + 5, py + 3, 0)
        end
        if dmg >= 2 then
          pset(px + 1, py + 5, 0)
          pset(px + 6, py + 6, 0)
          pset(px + 4, py + 4, 0)
        end

        if not self:is_mineable(x, y) then
          for py2 = py, py + self.block_size - 1, 2 do
            for px2 = px + (py2 % 2), px + self.block_size - 1, 2 do
              pset(px2, py2, 1)
            end
          end
        end
      end
    end
  end

  local cx = gx + (self.cursor.x - 1) * self.block_size
  local cy = gy + (self.cursor.y - 1) * self.block_size + self.cursor_bob
  local cc = self:is_mineable(self.cursor.x, self.cursor.y) and 11 or 8
  rect(cx - 1, cy - 1, cx + self.block_size, cy + self.block_size, cc)

  local stat_y = gy + gh + 8
  spr(1, gx - 10, stat_y - 1)
  print("gOLD mINED: " .. self.gold_found:tostr(), gx, stat_y, 10)
  local gps = bignum:new(self.game.miners * self.game.player.pick_lvl):mul2(min(self.prestige, 15))
  spr(5, gx - 10, stat_y + 9)
  print(gps:tostr() .. ' g/sEC (+'..self.miner_gold:tostr()..' g)', gx, stat_y + 11, 10)

  print("❎ mINE  🅾️ eXIT", 2, 120, 6)
end
