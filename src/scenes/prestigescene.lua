-- prestige

prestigescene = {}

function prestigescene:init(game_ref)
  self.game = game_ref

  input:bind({
    [input.button.o] = function() scene:pop() end
  })
end

function prestigescene:draw()
  cls()
  print('pRESTIGE sCENE', 40, 60, 8)
end
