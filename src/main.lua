-- main

function _init()
  app:init({
    name = "ridgerunner_v1",
    title = "Ridge Runner v1",
    defaults = {},
    -- boolean flags (all packed into address 60)
    -- up to 16 flags supported, addresses 61-63 free
    flags = {
      music_on = true
    }
  })

  options = app:load_options() or app:copy_flags_defaults()

  mountains:init()

  -- register all scenes
  scene:register('game', gamescene)
  scene:register('title', titlescene)

  scene:switch('title')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end
