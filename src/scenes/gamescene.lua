gamescene = {}

function gamescene:init()
  -- game data
  self.wave = 1
  self.battle_timer = 0
  self.battle_msg = ""
  self.msg_timer = 0
  self.gold = 0

  self.player = {
    x = 20,
    y = 80,
    base_y = 80,
    hp = 10,
    max_hp = 10,
    atk = 3,
    armor = 0,
    spr = 16
  }
  self.enemy = nil

  -- upgrade costs (increase after each purchase)
  self.costs = {
    atk = 10,
    hp = 8,
    armor = 15
  }

  -- submenus for player menu
  local inv_menu = menu:new({
    {label = 'uSE iTEM', action = function() return true end},
    {label = 'dROP iTEM', action = function() return true end},
    {label = 'eXAMINE', action = function() return true end}
  })

  local shop_menu = menu:new({
    {
      label = function()
        return 'aTK +1 (' .. self.costs.atk .. 'g)'
      end,
      enabled = function()
        return self.gold >= self.costs.atk
      end,
      action = function()
        self.gold -= self.costs.atk
        self.player.atk += 1
        self.costs.atk = flr(self.costs.atk * 1.5)
        sfx(5, 3)
      end
    },
    {
      label = function()
        return 'hP +5 (' .. self.costs.hp .. 'g)'
      end,
      enabled = function()
        return self.gold >= self.costs.hp
      end,
      action = function()
        self.gold -= self.costs.hp
        self.player.max_hp += 5
        self.player.hp += 5
        self.costs.hp = flr(self.costs.hp * 1.5)
        sfx(5, 3)
      end
    },
    {
      label = function()
        return 'aRMOR +1 (' .. self.costs.armor .. 'g)'
      end,
      enabled = function()
        return self.gold >= self.costs.armor
      end,
      action = function()
        self.gold -= self.costs.armor
        self.player.armor += 1
        self.costs.armor = flr(self.costs.armor * 1.5)
        sfx(5, 3)
      end
    }
  })

  local save_menu = menu:new({
    {label = 'sAVE gAME', action = function() return true end},
    {label = 'lOAD gAME', action = function() return true end},
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
        self.battle_timer = 30
        self.player_turn = true
        self:show_msg("eNEMY aPPROACHED!")

        -- stop enemy horizontal movement, keep bobbing
        if self.enemy then
          tween:cancel_all(self.enemy)
          tween:loop(self.enemy, {y = self.enemy.base_y - 3}, 15, {ease = tween.ease.in_out_quad})
        end
      end,
      update = function(s, data)
        self.battle_timer -= 1

        if self.battle_timer <= 0 then
          if self.player_turn then
            self:player_attack()
          else
            self:enemy_attack()
          end
          self.battle_timer = 30
        end
      end
    },

    victory = {
      init = function(s, data)
        -- gold reward scales with wave
        local reward = 5 + self.wave * 2
        self.gold += reward
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
        self.gold += 1
        sfx(2, 3)
      end
    end
  })
end

function gamescene:spawn_enemy()
  local base_hp = 5 + self.wave * 2
  local base_atk = 1 + flr(self.wave / 2)
  local base_y = 80

  self.enemy = {
    x = 140,
    y = base_y,
    base_y = base_y,
    hp = base_hp,
    max_hp = base_hp,
    atk = base_atk,
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
  self.player.y = self.player.base_y
end

function gamescene:show_msg(msg)
  self.battle_msg = msg
  self.msg_timer = 45
end

function gamescene:player_attack()
  if not self.enemy then return end

  -- attack lunge animation
  local orig_x = self.player.x
  tween:new(self.player, {x = orig_x + 8}, 6, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.player, {x = orig_x}, 6, {ease = tween.ease.in_quad})
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

  self.player_turn = false
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

  -- player hit reaction
  local player_orig_x = self.player.x
  tween:new(self.player, {x = player_orig_x - 4}, 4, {
    ease = tween.ease.out_quad,
    on_complete = function()
      tween:new(self.player, {x = player_orig_x}, 8, {ease = tween.ease.out_elastic})
    end
  })

  if self.player.hp <= 0 then
    self.player.hp = 0
    self.fsm:switch('defeat')
    return
  end

  self.player_turn = true
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
  print("★" .. self.gold, 2, 10, 10)

  -- right side: player stats
  self:print_right("aTK " .. self.player.atk, 2, 8)
  self:print_right("aRM " .. self.player.armor, 10, 12)
  self:print_right("hP " .. self.player.hp .. "/" .. self.player.max_hp, 18, 11)

  -- player hp bar
  local bar_w = 30
  local hp_pct = mid(0, self.player.hp / self.player.max_hp, 1)
  rectfill(10, 70, 10 + bar_w, 74, 1)
  rectfill(10, 70, 10 + bar_w * hp_pct, 74, 11)
  rect(10, 70, 10 + bar_w, 74, 5)

  -- enemy hp bar
  if self.enemy then
    local ehp_pct = mid(0, self.enemy.hp / self.enemy.max_hp, 1)
    rectfill(88, 70, 88 + bar_w, 74, 1)
    rectfill(88, 70, 88 + bar_w * ehp_pct, 74, 8)
    rect(88, 70, 88 + bar_w, 74, 5)
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
