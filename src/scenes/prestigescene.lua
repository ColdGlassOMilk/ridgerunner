-- prestige

prestigescene = {
  draws_underneath = true,    -- scene below still draws
  updates_underneath = true  -- scene below pauses updating
}

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
