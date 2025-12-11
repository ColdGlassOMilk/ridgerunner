-- main

function _init()
  app:init({
    name = "pico8_bp_v1",
    title = "Boilerplate v1",
    defaults = {
      bgcol = 1,
      timer = 0
    }
  })

  -- register all scenes
  scene:register('title', title_scene)
  scene:register('game', game_scene)
  scene:register('pause', pause_scene)

  scene:switch('title')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end
