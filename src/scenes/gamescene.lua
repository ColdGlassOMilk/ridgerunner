
gamescene = {}

function gamescene:init()
  input:bind({
    [input.button.x] = function() scene:switch('title') end
  })
end

function gamescene:update()
  mountains:update()
end

function gamescene:draw()
  cls()
  mountains:draw()
end
