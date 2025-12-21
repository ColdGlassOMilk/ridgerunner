-- main

function _init()
  app:init({
    name = "ridgerunner_v1",
    defaults = {
      -- player stats
      hp = 10,
      max_hp = 10,
      atk = 3,
      armor = 0,
      spd = 10,
      -- progress
      wave = 1,
      gold_m = 0,
      gold_e = 0
    },
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
  scene:register('mine', minescene)
  scene:register('title', titlescene)

  scene:switch('title')
end

function _update()
  input:update()
  tween:update()
  scene:update()
end

function _draw()
  scene:draw()
end
