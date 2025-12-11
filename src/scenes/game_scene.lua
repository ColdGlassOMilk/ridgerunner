-- game scene

game_scene = {}

function game_scene:bgcol_selected(col)
  return self.data.bgcol == col
end

function game_scene:save(slot_num)
  slot:save(slot_num, {
    bgcol = self.data.bgcol,
    timer = self.data.timer
  })
  return true
end

function game_scene:load(slot_num)
  local data = slot:load(slot_num)
  if data then
    scene:switch('game')
    self.data.bgcol = data.bgcol
    self.data.timer = data.timer or 0
  end
end

function game_scene:init()
  self.data = app:copy_defaults()

  local m = self
  self.game_menu = menu:new({
    {label = "resume", action = function() return true end},
    {label = "new game", action = function()
      scene:switch("game")
    end},
    {label = "save", sub_menu = menu:new({
      {label = "slot 1", action = function() return game_scene:save(1) end},
      {label = "slot 2", action = function() return game_scene:save(2) end},
      {label = "slot 3", action = function() return game_scene:save(3) end}
    })},
    {label = "bg color", sub_menu = menu:new({
      {label = "black", action = function() m.data.bgcol = 0 end},
      {label = "blue", sub_menu = menu:new({
        {label = "light", action = function() m.data.bgcol = 12 end},
        {label = "dark", action = function() m.data.bgcol = 1 end},
      })},
      {label = "burgundy", action = function() m.data.bgcol = 2 end},
      {label = "green", action = function() m.data.bgcol = 3 end,
        enabled = function() return not m:bgcol_selected(3) end},
      {label = "brown", action = function() m.data.bgcol = 4 end}
    })},
    {label = "exit", action = function()
      scene:switch('title')
    end}
  }, 2, 2)

  -- bind scene-level input
  input:bind({
    [input.button.x] = function()
      m.game_menu:show()
    end,
    [input.button.o] = function()
      scene:push('pause')
    end
  })
end

function game_scene:update()
  self.data.timer += 1

  if self.game_menu.active then
    self.game_menu:update()
  end
end

function game_scene:draw()
  cls(self.data.bgcol)

  print("timer: " .. self.data.timer, 2, 120, 7)
  print("❎ menu  🅾️ pause", 2, 2, 6)

  if self.game_menu.active then
    self.game_menu:draw()
  end
end

function game_scene:exit()
  if self.game_menu.active then
    self.game_menu:hide()
    self.game_menu:close_parents()
  end
  -- input is reset by scene:switch, no need to clear manually
end

-- called when another scene is pushed on top
function game_scene:pause()
  -- could pause music, timers, etc
end

-- called when returning from a pushed scene
function game_scene:resume()
  -- could resume music, etc
end
