-- title scene

title_scene = {}

function title_scene:init()
  self.title_menu = menu:new({
    {label="new game", action=function() scene:switch('game') end},
    {label="load", sub_menu=menu:new({
      {label="slot 1", action=function() return game_scene:load(1) end, enabled=function() return slot:exists(1) end},
      {label="slot 2", action=function() return game_scene:load(2) end, enabled=function() return slot:exists(2) end},
      {label="slot 3", action=function() return game_scene:load(3) end, enabled=function() return slot:exists(3) end}
    })}
  }, nil, nil, {
    closeable = false,
    show_bg = false,
    show_border = false,
    show_shadow = false
  })

  self.title_menu:show()
end

function title_scene:update()
  self.title_menu:update()
end

function title_scene:draw()
  cls(1)

  self.title_menu:draw()
end

function title_scene:exit()
  self.title_menu:hide()
  input:clr()
end
