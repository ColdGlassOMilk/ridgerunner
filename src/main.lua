-- main

function _init()
  scene:register('game', game_scene)
  scene:switch('game')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end
