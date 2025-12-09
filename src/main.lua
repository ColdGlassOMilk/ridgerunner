-- main

function _init()
  slot:init("pico8_bp", {"bgcol"})
  scene:register('title', title_scene)
  scene:register('game', game_scene)
  scene:switch('title')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end
