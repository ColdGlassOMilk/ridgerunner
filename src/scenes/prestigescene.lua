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
  -- cls(1)
  rectfill(35, 55, 100, 70, 1)
  print('pRESTIGE sCENE', 40, 60, 8)
end
