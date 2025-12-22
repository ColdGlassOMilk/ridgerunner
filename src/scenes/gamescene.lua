-- game scene

-- Enemies should have color replaced occassionally (every 5-10 waves?)
-- color should coorespond to a buffed trait, like speed, attack, etc.

-- Prestige system for replayability

gamescene = {}

-- helper: create upgrade menu item
local function upgrade_item(gs, stat, label, amt)
  return {
    label = function() return label..' +'..amt..' ('..gs.costs[stat]:tostr()..'g)' end,
    enabled = function() return gs.gold:gte(gs.costs[stat]) end,
    action = function()
      gs.gold:sub(gs.costs[stat]:clone())
      local key = stat == 'hp' and 'max_hp' or stat
      gs.player[key] += amt
      if stat == 'hp' then gs.player.hp += amt end
      gs:recalc_costs()
      sfx(5, 3)
    end
  }
end

-- helper: create miner hire menu item
local function miner_item(gs)
  return {
    label = function() return 'hIRE mINER ('..gs.costs.miner:tostr()..'g)' end,
    enabled = function() return gs.gold:gte(gs.costs.miner) end,
    action = function()
      gs.gold:sub(gs.costs.miner:clone())
      gs.miners += 1
      gs:recalc_costs()
      sfx(5, 3)
    end
  }
end

function gamescene:init(loaded_data)
  tween:clear()
  local data = loaded_data or app:copy_defaults()

  self.wave = data.wave or 1
  self.battle_msg, self.msg_timer = "", 0

  -- gold (bignum)
  self.gold = bignum:new(data.gold_m and 0 or (data.gold or 0))
  if data.gold_m then self.gold:unpack(data.gold_m, data.gold_e) end

  -- miners for auto-mining
  self.miners, self.mine_timer = data.miners or 0, 0

  self.player = {
    x = 20, base_x = 20, y = 80, base_y = 80,
    hp = data.hp or 10, max_hp = data.max_hp or 10,
    atk = data.atk or 3, armor = data.armor or 0, spd = data.spd or 10,
    action_timer = 0, spr = 16,
    pick_lvl = data.pick_lvl or 1
  }
  self.enemy = nil
  self:recalc_costs()

  -- menus
  local inv_menu = menu:new({
    {label='eNTER mINE', action=function() scene:switch('mine', self) end},
    miner_item(self),
    upgrade_item(self, 'pick_lvl', 'pICKAXE', 1)
  })

  local shop_menu = menu:new({
    upgrade_item(self, 'atk', 'aTK', 1),
    upgrade_item(self, 'hp', 'hP', 5),
    upgrade_item(self, 'armor', 'aRMOR', 1),
    upgrade_item(self, 'spd', 'sPD', 2)
  })

  local save_sub = menu:new(slot:save_menu(function(n) self:save_game(n) end))
  local load_sub = menu:new(slot:load_menu())

  local save_menu = menu:new({
    {label='sAVE', sub_menu=save_sub},
    {label='lOAD', sub_menu=load_sub},
    {label='pRESTIGE', enabled=false},
    {label='qUIT', action=function() scene:switch('title') end}
  })

  player_menu = menu:new({
    {spr=2, sub_menu=shop_menu},
    {spr=1, sub_menu=inv_menu},
    {spr=3, sub_menu=save_menu}
  }, nil, 112, {horizontal=true, icon_size=8, spacing=4})

  -- fsm
  self.fsm = state:new({
    walking = {
      init = function()
        self:spawn_enemy()
        tween:cancel_all(self.player)
        tween:loop(self.player, {y=self.player.base_y-2}, 20, {ease=tween.ease.in_out_quad})
      end,
      update = function() mountains:update() end
    },

    battle = {
      init = function()
        self:show_msg("eNEMY aPPROACHED!")
        local base = 60
        self.player.action_timer = flr(base * 10 / self.player.spd)
        if self.enemy then
          self.enemy.action_timer = flr(base * 10 / self.enemy.spd)
          tween:cancel_all(self.enemy)
          tween:loop(self.enemy, {y=self.enemy.base_y-3}, 15, {ease=tween.ease.in_out_quad})
        end
      end,
      update = function()
        if not self.enemy or self.enemy.dying then return end
        self.player.action_timer -= 1
        self.enemy.action_timer -= 1
        if self.player.action_timer <= 0 then
          self:player_attack()
          self.player.action_timer = flr(60 * 10 / self.player.spd)
        end
        if self.enemy and not self.enemy.dying and self.enemy.action_timer <= 0 then
          self:enemy_attack()
          self.enemy.action_timer = flr(60 * 10 / self.enemy.spd)
        end
      end
    },

    victory = {
      init = function()
        local reward = 5 + self.wave * 2
        self.gold:add(reward)
        self:show_msg("vICTORY! +"..reward.."g")
        self.timer = 60
        self:reset_player()
      end,
      update = function()
        self.timer -= 1
        if self.timer <= 0 then self.wave += 1 self.fsm:switch('walking') end
      end
    },

    defeat = {
      init = function()
        self:show_msg("dEFEATED!")
        self.timer = 90
        tween:cancel_all(self.player)
        tween:new(self.player, {y=self.player.base_y+4}, 10, {ease=tween.ease.out_quad})
      end,
      update = function()
        self.timer -= 1
        if self.timer <= 0 then self:reset_player() self.fsm:switch('walking') end
      end
    }
  }, 'walking')

  input:bind({
    [input.button.x] = function()
      if not player_menu.active then player_menu:show() end
    end
  })
end

function gamescene:recalc_costs()
  local base = {atk=10, hp=8, armor=15, spd=12, pick_lvl=100}
  local defs = {atk=3, max_hp=10, armor=0, spd=10, pick_lvl=1}
  local per = {atk=1, max_hp=5, armor=1, spd=2, pick_lvl=1}
  self.costs = {}

  for stat, bc in pairs(base) do
    local key = stat == 'hp' and 'max_hp' or stat
    local cost = bignum:new(bc)
    for i=1, (self.player[key] - defs[key]) / per[key] do cost:mul(1.5) end
    self.costs[stat] = cost
  end

  -- miner cost: base 50, scales 1.2x per owned
  local mc = bignum:new(50)
  for i=1, self.miners do mc:mul(1.2) end
  self.costs.miner = mc
end

function gamescene:spawn_enemy()
  local by = 80
  self.enemy = {
    x=140, y=by, base_y=by,
    hp = 5 + self.wave*2,
    max_hp = 5 + self.wave*2,
    atk = 1 + flr(self.wave/2),
    spd = 8 + flr(self.wave*0.5),
    action_timer=0, spr=18
  }

  local tx = self.player.x + 16
  local dur = max((140 - tx) * (2 - self.wave*0.05), 60)
  tween:cancel_all(self.enemy)
  tween:new(self.enemy, {x=tx}, dur, {
    ease=tween.ease.out_quad,
    on_complete=function() self.fsm:switch('battle') end
  })
  tween:loop(self.enemy, {y=by-4}, 12, {ease=tween.ease.in_out_quad})
end

function gamescene:reset_player()
  self.player.hp = self.player.max_hp
  self.player.x, self.player.y = self.player.base_x, self.player.base_y
  self.player.action_timer = 0
end

function gamescene:show_msg(msg)
  self.battle_msg, self.msg_timer = msg, 45
end

function gamescene:save_game(n)
  local gm, ge = self.gold:pack()
  slot:save(n, {
    hp=self.player.hp, max_hp=self.player.max_hp,
    atk=self.player.atk, armor=self.player.armor, spd=self.player.spd,
    wave=self.wave, gold_m=gm, gold_e=ge, miners=self.miners, pick_lvl = self.player.pick_lvl
  })
  self:show_msg("gAME sAVED!")
end

function gamescene:load_game(n)
  local d = slot:load(n)
  if not d then return end

  self.player.hp, self.player.max_hp = d.hp, d.max_hp
  self.player.atk, self.player.armor, self.player.spd = d.atk, d.armor, d.spd
  self.wave, self.miners = d.wave, d.miners or 0
  self.player.pick_lvl = d.pick_lvl or 1

  if d.gold_m then
    self.gold:unpack(d.gold_m, d.gold_e)
  elseif d.gold then
    self.gold:set(d.gold)
  end

  self:recalc_costs()
  tween:cancel_all(self.player)
  if self.enemy then tween:cancel_all(self.enemy) end
  self.enemy = nil
  self.player.x, self.player.y = self.player.base_x, self.player.base_y
  self.fsm:switch('walking')
  self:show_msg("gAME lOADED!")
end

function gamescene:player_attack()
  if not self.enemy or self.enemy.dying then return end

  tween:new(self.player, {x=self.player.base_x+8}, 6, {
    ease=tween.ease.out_quad,
    on_complete=function()
      tween:new(self.player, {x=self.player.base_x}, 6, {ease=tween.ease.in_quad})
    end
  })

  local dmg = self.player.atk + flr(rnd(3))
  self.enemy.hp -= dmg
  self:show_msg("hIT FOR "..dmg.." dMG!")
  sfx(5, 3)

  if self.enemy.hp <= 0 then
    self.enemy.dying = true
    tween:cancel_all(self.enemy)
    tween:new(self.enemy, {y=self.enemy.base_y+8, x=self.enemy.x+20}, 20, {
      ease=tween.ease.out_quad,
      on_complete=function()
        self.enemy = nil
        self.fsm:switch('victory')
      end
    })
  end
end

function gamescene:enemy_attack()
  if not self.enemy or self.enemy.dying then return end

  tween:new(self.enemy, {x=self.enemy.x-8}, 6, {
    ease=tween.ease.out_quad,
    on_complete=function()
      tween:new(self.enemy, {x=self.player.x+16}, 6, {ease=tween.ease.in_quad})
    end
  })

  local dmg = max(0, self.enemy.atk - self.player.armor) + flr(rnd(2))
  self.player.hp -= dmg
  self:show_msg("tOOK "..dmg.." dMG!")
  sfx(6, 3)

  tween:new(self.player, {x=self.player.base_x-4}, 4, {
    ease=tween.ease.out_quad,
    on_complete=function()
      tween:new(self.player, {x=self.player.base_x}, 8, {ease=tween.ease.out_elastic})
    end
  })

  if self.player.hp <= 0 then
    self.player.hp = 0
    self.fsm:switch('defeat')
  end
end

function gamescene:update()
  self.fsm:update()
  player_menu:update()
  if self.msg_timer > 0 then self.msg_timer -= 1 end

  -- auto-mining: each miner generates 1 gold per second (30 frames)
  if self.miners > 0 then
    self.mine_timer += 1
    if self.mine_timer >= 30 then
      self.gold:add(self.miners * self.player.pick_lvl)
      self.mine_timer = 0
    end
  end
end

function gamescene:draw()
  cls()
  mountains:draw()

  -- sprites
  spr(self.player.spr, self.player.x, self.player.y, 2, 2)
  if self.enemy then spr(self.enemy.spr, self.enemy.x, self.enemy.y, 2, 2) end

  -- hud
  print("wAVE "..self.wave, 2, 2, 6)
  spr(4, 1, 9) -- gold
  print(self.gold:tostr()..' g', 10, 10, 10)
  spr(5, 1, 17) -- miners
  print(self.miners, 10, 19, 6)

  local function pr(t,y,c) local w=print(t,0,-100) print(t,126-w,y,c) end
  pr("aTK "..self.player.atk, 2, 8)
  pr("sPD "..self.player.spd, 10, 11)
  pr("aRM "..self.player.armor, 18, 12)
  pr("hP "..self.player.hp.."/"..self.player.max_hp, 26, 11)

  -- health/action bars
  local bw = 30
  local function bar(x,y,pct,c)
    rectfill(x,y,x+bw,y+4,1)
    rectfill(x,y,x+bw*pct,y+4,c)
    rect(x,y,x+bw,y+4,5)
  end

  bar(10, 70, mid(0, self.player.hp/self.player.max_hp, 1), 11)

  if self.fsm.current == "battle" and self.enemy then
    local pmax = flr(60*10/self.player.spd)
    rectfill(10, 76, 10+bw, 78, 1)
    rectfill(10, 76, 10+bw*mid(0, 1-self.player.action_timer/pmax, 1), 78, 12)
    rect(10, 76, 10+bw, 78, 5)
  end

  if self.enemy then
    bar(88, 70, mid(0, self.enemy.hp/self.enemy.max_hp, 1), 8)
    if self.fsm.current == "battle" then
      local emax = flr(60*10/self.enemy.spd)
      rectfill(88, 76, 88+bw, 78, 1)
      rectfill(88, 76, 88+bw*mid(0, 1-self.enemy.action_timer/emax, 1), 78, 12)
      rect(88, 76, 88+bw, 78, 5)
    end
  end

  -- battle message
  if self.msg_timer > 0 then
    local w = print(self.battle_msg, 0, -100)
    print(self.battle_msg, 64-w/2, 30, 7)
  end

  -- menu hint
  if not player_menu.active then print("❎", 62, 120, 6) end
  player_menu:draw()
end

function gamescene:pause()
  if player_menu.active then player_menu:hide() end
end
