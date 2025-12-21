gamescene = {}

function gamescene:init(loaded_data)
  -- game data - use loaded data or defaults
  local data = loaded_data or app:copy_defaults()

  self.wave = data.wave or 1
  self.battle_timer = 0
  self.battle_msg = ""
  self.msg_timer = 0

  -- gold uses bignum now
  if data.gold_m then
    -- loaded from save with bignum format
    self.gold = bignum:new():unpack(data.gold_m, data.gold_e)
  elseif data.gold then
    -- legacy save or default
    self.gold = bignum:new(data.gold)
  else
    self.gold = bignum:new(0)
  end

  self.player = {
    x = 20,
    base_x = 20,
    y = 80,
    base_y = 80,
    hp = data.hp or 10,
    max_hp = data.max_hp or 10,
    atk = data.atk or 3,
    armor = data.armor or 0,
    spd = data.spd or 10,
    action_timer = 0,
    spr = 16
  }
  self.enemy = nil

  -- upgrade amounts
  self.upgrade_amounts = {
    atk = 1,
    hp = 5,
    armor = 1,
    spd = 2
  }

  -- calculate costs based on current stats
  self:recalc_costs()

  -- submenus for player menu
  local inv_menu = menu:new({
    {label = 'uSE iTEM', action = function() return true end},
    {label = 'dROP iTEM', action = function() return true end},
    {label = 'eXAMINE', action = function() return true end}
  })

  local shop_menu = menu:new({
    {
      label = function()
        return 'aTK +1 (' .. self.costs.atk:tostr() .. 'g)'
      end,
      enabled = function()
        return self.gold:gte(self.costs.atk)
      end,
      action = function()
        self.gold:sub(self.costs.atk:clone())
        self.player.atk += self.upgrade_amounts.atk
        self:recalc_costs()
        sfx(5, 3)
      end
    },
    {
      label = function()
        return 'hP +5 (' .. self.costs.hp:tostr() .. 'g)'
      end,
      enabled = function()
        return self.gold:gte(self.costs.hp)
      end,
      action = function()
        self.gold:sub(self.costs.hp:clone())
        self.player.max_hp += self.upgrade_amounts.hp
        self.player.hp += self.upgrade_amounts.hp
        self:recalc_costs()
        sfx(5, 3)
      end
    },
    {
      label = function()
        return 'aRMOR +1 (' .. self.costs.armor:tostr() .. 'g)'
      end,
      enabled = function()
        return self.gold:gte(self.costs.armor)
      end,
      action = function()
        self.gold:sub(self.costs.armor:clone())
        self.player.armor += self.upgrade_amounts.armor
        self:recalc_costs()
        sfx(5, 3)
      end
    },
    {
      label = function()
        return 'sPD +2 (' .. self.costs.spd:tostr() .. 'g)'
      end,
      enabled = function()
        return self.gold:gte(self.costs.spd)
      end,
      action = function()
        self.gold:sub(self.costs.spd:clone())
        self.player.spd += self.upgrade_amounts.spd
        self:recalc_costs()
        sfx(5, 3)
      end
    }
  })

  local save_submenu = menu:new({
    {label=function()
      if slot:exists(1) then
        local d = slot:load(1)
        return 'sLOT 1 - wAVE ' .. d.wave
      end
      return 'sLOT 1 - eMPTY'
    end, action=function()
      self:save_game(1)
      return true
    end},
    {label=function()
      if slot:exists(2) then
        local d = slot:load(2)
        return 'sLOT 2 - wAVE ' .. d.wave
      end
      return 'sLOT 2 - eMPTY'
    end, action=function()
      self:save_game(2)
      return true
    end},
    {label=function()
      if slot:exists(3) then
        local d = slot:load(3)
        return 'sLOT 3 - wAVE ' .. d.wave
      end
      return 'sLOT 3 - eMPTY'
    end, action=function()
      self:save_game(3)
      return true
    end}
  })

  local load_submenu = menu:new({
    {label=function()
      if slot:exists(1) then
        local d = slot:load(1)
        return 'sLOT 1 - wAVE ' .. d.wave
      end
      return 'sLOT 1 - eMPTY'
    end, enabled=function() return slot:exists(1) end, action=function()
      self:load_game(1)
      return true
    end},
    {label=function()
      if slot:exists(2) then
        local d = slot:load(2)
        return 'sLOT 2 - wAVE ' .. d.wave
      end
      return 'sLOT 2 - eMPTY'
    end, enabled=function() return slot:exists(2) end, action=function()
      self:load_game(2)
      return true
    end},
    {label=function()
      if slot:exists(3) then
        local d = slot:load(3)
        return 'sLOT 3 - wAVE ' .. d.wave
      end
      return 'sLOT 3 - eMPTY'
    end, enabled=function() return slot:exists(3) end, action=function()
      self:load_game(3)
      return true
    end}
  })

  local save_menu = menu:new({
    {label = 'sAVE gAME', sub_menu = save_submenu},
    {label = 'lOAD gAME', sub_menu = load_submenu},
    {label = 'qUIT', action = function() scene:switch('title') end}
  })

  player_menu = menu:new({
    {spr = 1, sub_menu = inv_menu},
    {spr = 2, sub_menu = shop_menu},
    {spr = 3, sub_menu = save_menu},
  }, nil, 112, {
    horizontal = true,
    icon_size = 8,
    spacing = 4
  })

  -- state machine
  self.fsm = state:new({
    walking = {
      init = function(s, data)
        self:spawn_enemy()
        -- player idle bob
        tween:cancel_all(self.player)
        tween:loop(self.player, {y = self.player.base_y - 2}, 20, {ease = tween.ease.in_out_quad})
      end,
      update = function(s, data)
        mountains:update()
      end
    },

    battle = {
      init = function(s, data)
        self:show_msg("eNEMY aPPROACHED!")

        -- initialize action timers based on speed
        -- higher speed = lower timer = attacks sooner
        local base_action_time = 60
        self.player.action_timer = flr(base_action_time * 10 / self.player.spd)
        if self.enemy then
          self.enemy.action_timer = flr(base_action_time * 10 / self.enemy.spd)
        end

        -- stop enemy horizontal movement, keep bobbing
        if self.enemy then
          tween:cancel_all(self.enemy)
          tween:loop(self.enemy, {y = self.enemy.base_y - 3}, 15, {ease = tween.ease.in_out_quad})
        end
      end,
      update = function(s, data)
        if not self.enemy or self.enemy.dying then return end

        -- tick down both timers
        self.player.action_timer -= 1
        self.enemy.action_timer -= 1

        -- check who attacks
        if self.player.action_timer <= 0 then
          self:player_attack()
          -- reset timer based on speed
          local base_action_time = 60
          self.player.action_timer = flr(base_action_time * 10 / self.player.spd)
        end

        -- enemy may have died from player attack
        if self.enemy and not self.enemy.dying and self.enemy.action_timer <= 0 then
          self:enemy_attack()
          -- reset timer based on speed
          local base_action_time = 60
          self.enemy.action_timer = flr(base_action_time * 10 / self.enemy.spd)
        end
      end
    },

    victory = {
      init = function(s, data)
        -- gold reward scales with wave
        local reward = 5 + self.wave * 2
        self.gold:add(reward)
        self:show_msg("vICTORY! +" .. reward .. "g")
        self.victory_timer = 60
        self:reset_player()
      end,
      update = function(s, data)
        self.victory_timer -= 1
        if self.victory_timer <= 0 then
          self.wave += 1
          self.fsm:switch('walking')
        end
      end
    },

    defeat = {
      init = function(s, data)
        self:show_msg("dEFEATED!")
        self.defeat_timer = 90

        -- player death animation
        tween:cancel_all(self.player)
        tween:new(self.player, {y = self.player.base_y + 4}, 10, {ease = tween.ease.out_quad})
      end,
      update = function(s, data)
        self.defeat_timer -= 1
        if self.defeat_timer <= 0 then
          self:reset_player()
          self.fsm:switch('walking')
        end
      end
    }
  }, 'walking')

  -- scene-level input
  input:bind({
    [input.button.x] = function()
      if not player_menu.active then
        player_menu:show()
      end
    end,
    [input.button.o] = function()
      if not player_menu.active then
        self.gold:add(10000)
        sfx(2, 3)
      end
    end
  })
end

function gamescene:spawn_enemy()
  local base_hp = 5 + self.wave * 2
  local base_atk = 1 + flr(self.wave / 2)
  local base_spd = 8 + flr(self.wave * 0.5)  -- enemies get faster each wave
  local base_y = 80

  self.enemy = {
    x = 140,
    y = base_y,
    base_y = base_y,
    hp = base_hp,
    max_hp = base_hp,
    atk = base_atk,
    spd = base_spd,
    action_timer = 0,
    spr = 32
  }

  -- calculate tween duration based on distance
  local target_x = self.player.x + 16
  local distance = self.enemy.x - target_x
  local duration = distance * (2 - self.wave * 0.05)  -- faster each wave
  duration = max(duration, 60)  -- minimum 1 second

  -- smooth approach tween
  tween:cancel_all(self.enemy)
  tween:new(self.enemy, {x = target_x}, duration, {
    ease = tween.ease.out_quad,
    on_complete = function()
      self.fsm:switch('battle')
    end
  })

  -- bobbing while walking
  tween:loop(self.enemy, {y = base_y - 4}, 12, {ease = tween.ease.in_out_quad})
end

function gamescene:reset_player()
  self.player.hp = self.player.max_hp
  self.player.x = self.player.base_x
  self.player.y = self.player.base_y
  self.player.action_timer = 0
end

function gamescene:show_msg(msg)
  self.battle_msg = msg
  self.msg_timer = 45
end

function gamescene:recalc_costs()
  -- base costs
  local base = {atk = 10, hp = 8, armor = 15, spd = 12}
  -- default stat values
  local defaults = {atk = 3, max_hp = 10, armor = 0, spd = 10}
  -- upgrade amounts
  local per = {atk = 1, max_hp = 5, armor = 1, spd = 2}

  self.costs = {}
  for stat, base_cost in pairs(base) do
    local key = stat == "hp" and "max_hp" or stat
    local current = self.player[key]
    local upgrades = (current - defaults[key]) / per[key]
    -- use bignum for costs to handle large values
    -- multiply by 1.5 repeatedly to avoid overflow from 1.5^n
    local cost = bignum:new(base_cost)
    for i = 1, upgrades do
      cost:mul(1.5)
    end
    self.costs[stat] = cost
  end
end

function gamescene:save_game(slot_num)
  -- pack gold into mantissa and exponent for save
  local gold_m, gold_e = self.gold:pack()
  local data = {
    hp = self.player.hp,
    max_hp = self.player.max_hp,
    atk = self.player.atk,
    armor = self.player.armor,
    spd = self.player.spd,
    wave = self.wave,
    gold_m = gold_m,
    gold_e = gold_e
  }
  slot:save(slot_num, data)
  self:show_msg("gAME sAVED!")
end

function gamescene:load_game(slot_num)
  local data = slot:load(slot_num)
  if data then
    -- restore player stats
    self.player.hp = data.hp
    self.player.max_hp = data.max_hp
    self.player.atk = data.atk
    self.player.armor = data.armor
    self.player.spd = data.spd

    -- restore progress
    self.wave = data.wave

    -- restore gold (handle both old and new save formats)
    if data.gold_m then
      self.gold:unpack(data.gold_m, data.gold_e)
    elseif data.gold then
      self.gold:set(data.gold)
    end

    -- recalculate upgrade costs based on loaded stats
    self:recalc_costs()

    -- reset battle state
    tween:cancel_all(self.player)
    if self.enemy then
      tween:cancel_all(self.enemy)
    end
    self.enemy = nil
    self.player.x = self.player.base_x
    self.player.y = self.player.base_y

    -- restart from walking state
    self.fsm:switch('walking')

    self:show_msg("gAME lOADED!")
  end
end

function gamescene:player_attack()
  if not self.enemy or self.enemy.dying then return end

  -- attack lunge animation using base_x to prevent drift
  tween:new(self.player, {x = self.player.base_x + 8}, 6, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.player, {x = self.player.base_x}, 6, {ease = tween.ease.in_quad})
    end
  })

  local dmg = self.player.atk + flr(rnd(3))
  self.enemy.hp -= dmg
  self:show_msg("hIT FOR " .. dmg .. " dMG!")
  sfx(5, 3)

  -- enemy hit reaction
  local enemy_orig_x = self.enemy.x
  tween:new(self.enemy, {x = enemy_orig_x + 4}, 4, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.enemy, {x = enemy_orig_x}, 8, {ease = tween.ease.out_elastic})
    end
  })

  if self.enemy.hp <= 0 then
    -- mark as dying so no more attacks happen
    self.enemy.dying = true
    -- death animation
    tween:cancel_all(self.enemy)
    tween:new(self.enemy, {y = self.enemy.base_y + 20, x = self.enemy.x + 10}, 30, {
      ease = tween.ease.in_quad,
      on_complete = function()
        self.enemy = nil
        self.fsm:switch('victory')
      end
    })
    return
  end
end

function gamescene:enemy_attack()
  if not self.enemy then return end

  -- enemy lunge animation
  local orig_x = self.enemy.x
  tween:new(self.enemy, {x = orig_x - 8}, 6, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.enemy, {x = orig_x}, 6, {ease = tween.ease.in_quad})
    end
  })

  -- apply armor reduction
  local dmg = max(1, self.enemy.atk + flr(rnd(2)) - self.player.armor)
  self.player.hp -= dmg
  self:show_msg("eNEMY hIT FOR " .. dmg .. "!")
  sfx(6, 3)

  -- player hit reaction using base_x to prevent drift
  tween:new(self.player, {x = self.player.base_x - 4}, 4, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.player, {x = self.player.base_x}, 8, {ease = tween.ease.out_elastic})
    end
  })

  if self.player.hp <= 0 then
    self.player.hp = 0
    self.fsm:switch('defeat')
    return
  end
end

function gamescene:print_right(txt, y, col)
  local w = print(txt, 0, -100)
  print(txt, 126 - w, y, col)
end

function gamescene:update()
  self.fsm:update()
  player_menu:update()

  if self.msg_timer > 0 then
    self.msg_timer -= 1
  end
end

function gamescene:draw()
  cls()
  mountains:draw()

  -- player
  spr(self.player.spr, self.player.x, self.player.y)

  -- enemy
  if self.enemy then
    spr(self.enemy.spr, self.enemy.x, self.enemy.y)
  end

  -- left side: wave and gold
  print("wAVE " .. self.wave, 2, 2, 6)
  print("★" .. self.gold:tostr(), 2, 10, 10)

  -- right side: player stats
  self:print_right("aTK " .. self.player.atk, 2, 8)
  self:print_right("sPD " .. self.player.spd, 10, 11)
  self:print_right("aRM " .. self.player.armor, 18, 12)
  self:print_right("hP " .. self.player.hp .. "/" .. self.player.max_hp, 26, 11)

  -- player hp bar
  local bar_w = 30
  local hp_pct = mid(0, self.player.hp / self.player.max_hp, 1)
  rectfill(10, 70, 10 + bar_w, 74, 1)
  rectfill(10, 70, 10 + bar_w * hp_pct, 74, 11)
  rect(10, 70, 10 + bar_w, 74, 5)

  -- player action timer bar (shows when next attack happens)
  if self.fsm.current == "battle" and self.enemy then
    local base_action_time = 60
    local max_timer = flr(base_action_time * 10 / self.player.spd)
    local timer_pct = mid(0, 1 - self.player.action_timer / max_timer, 1)
    rectfill(10, 76, 10 + bar_w, 78, 1)
    rectfill(10, 76, 10 + bar_w * timer_pct, 78, 12)
    rect(10, 76, 10 + bar_w, 78, 5)
  end

  -- enemy hp bar
  if self.enemy then
    local ehp_pct = mid(0, self.enemy.hp / self.enemy.max_hp, 1)
    rectfill(88, 70, 88 + bar_w, 74, 1)
    rectfill(88, 70, 88 + bar_w * ehp_pct, 74, 8)
    rect(88, 70, 88 + bar_w, 74, 5)

    -- enemy action timer bar
    if self.fsm.current == "battle" then
      local base_action_time = 60
      local max_timer = flr(base_action_time * 10 / self.enemy.spd)
      local timer_pct = mid(0, 1 - self.enemy.action_timer / max_timer, 1)
      rectfill(88, 76, 88 + bar_w, 78, 1)
      rectfill(88, 76, 88 + bar_w * timer_pct, 78, 8)
      rect(88, 76, 88 + bar_w, 78, 5)
    end
  end

  -- battle message
  if self.msg_timer > 0 then
    local w = print(self.battle_msg, 0, -100)
    print(self.battle_msg, 64 - w / 2, 30, 7)
  end

  -- menu hint
  if not player_menu.active then
    print("❎ mENU  🅾️ +1g", 2, 120, 6)
  end

  player_menu:draw()
end
