-- game scene

game_scene = {
  bgcol = 1
}

function game_scene:bgcol_selected(col)
  return self.bgcol==col
end

function game_scene:init()
  self.bgcol = 1
  local m = self
  game_menu = menu:new({
    {label="new game", action=function() scene:switch("game") end},
    {label="bg color", sub_menu=menu:new({
      {label="black", action=function() m.bgcol = 0 end},
      {label="blue", sub_menu = menu:new({
        {label="light", action=function() m.bgcol = 12 end},
        {label="dark", action=function() m.bgcol = 1 end},
      })},
      {label="burgundy", action=function() m.bgcol = 2 end},
      {label="green", action=function() m.bgcol = 3 end, enabled=function() return not self:bgcol_selected(3) end},
      {label="brown", action=function() m.bgcol = 4 end}
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
  cls(self.bgcol)

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