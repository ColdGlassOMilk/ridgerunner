-- game scene

game_scene = {
  data = {
    bgcol = 1,
    player = {
      x, y = 63
    }
  }
}

function game_scene:bgcol_selected(col)
  return self.data.bgcol==col
end

function game_scene:save(slot_num)
  slot:save(slot_num, {
    bgcol = self.data.bgcol
  })
  return true
end

function game_scene:load(slot_num)
  local data = slot:load(slot_num)
  if data then
    scene:switch('game')
    self.data.bgcol = data.bgcol
  end
end

function game_scene:init()
  self.data.bgcol = 1
  local m = self
  slot:init("pico8_bp", {"bgcol"})
  game_menu = menu:new({
    {label="new game", action=function() scene:switch("game") end},
    {label="save", sub_menu=menu:new({
      {label="slot 1", action=function() return game_scene:save(1) end},
      {label="slot 2", action=function() return game_scene:save(2) end},
      {label="slot 3", action=function() return game_scene:save(3) end}
    })},
    {label="load", sub_menu=menu:new({
      {label="slot 1", action=function() return game_scene:load(1) end, enabled=function() return slot:exists(1) end},
      {label="slot 2", action=function() return game_scene:load(2) end, enabled=function() return slot:exists(2) end},
      {label="slot 3", action=function() return game_scene:load(3) end, enabled=function() return slot:exists(3) end}
    })},
    {label="bg color", sub_menu=menu:new({
      {label="black", action=function() m.data.bgcol = 0 end},
      {label="blue", sub_menu = menu:new({
        {label="light", action=function() m.data.bgcol = 12 end},
        {label="dark", action=function() m.data.bgcol = 1 end},
      })},
      {label="burgundy", action=function() m.data.bgcol = 2 end},
      {label="green", action=function() m.data.bgcol = 3 end, enabled=function() return not self:bgcol_selected(3) end},
      {label="brown", action=function() m.data.bgcol = 4 end}
    }
  )},
  {label="close", action=function() return true end}
  }, 2, 2)

  input:bind({
    [input.button.x] = function() game_menu:show() end
  })
end

function game_scene:update()
  if game_menu.active then game_menu:update() end
end

function game_scene:draw()
  cls(self.data.bgcol)

  if game_menu.active then game_menu:draw() end
end

function game_scene:exit()
  -- clean up input contexts
  if game_menu.active then
    game_menu:hide()
    game_menu:close_parents()
  end
  input:clr()
end
