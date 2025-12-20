player_menu = {
  active = false,
  y = 128  -- start off-screen (bottom)
}

function player_menu:update()
  -- tween system handles the animation
  -- TODO: Move input handling into scene/state bindings
end

function player_menu:draw()
  if not self.active and self.y >= 128 then return end

  -- draw at current y position
  rectfill(0, self.y, 127, self.y + 30, 1)
  rect(0, self.y, 127, self.y + 30, 5)
  print('player_menu', 5, self.y + 5, 8)
end

function player_menu:show()
  self.active = true
  tween:cancel_all(self)
  tween:new(self, {y = 97}, 15, {
    ease = tween.ease.out_back
  })
end

function player_menu:hide()
  tween:cancel_all(self)
  tween:new(self, {y = 128}, 12, {
    ease = tween.ease.in_quad,
    on_complete = function()
      self.active = false
    end
  })
end
