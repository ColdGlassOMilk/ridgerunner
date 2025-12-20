
gamescene = {}

function gamescene:init()
  -- input:bind({
  --   [input.button.x] = function() player_menu:show() end,
  --   [input.button.o] = function() player_menu:hide() end
  -- })

  self.fsm = state:new({
    main = {
      bindings = {
        [input.button.x] = function() self.fsm:switch('p_menu') end,
        [input.button.o] = function() scene:switch('title') end
      }
    },
    p_menu = {
      bindings = {
        [input.button.o] = function() self.fsm:switch('main') end
      },
      init = function() player_menu:show() end,
      exit = function() player_menu:hide() end
    }
  }, 'main')
end

function gamescene:update()
  mountains:update()
end

function gamescene:draw()
  cls()
  mountains:draw()

  player_menu:draw()
end
