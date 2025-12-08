-- scene

scene = {
  stack = {},
  scenes = {}
}

function scene:register(name, scn)
  self.scenes[name] = scn
end

function scene:switch(name, ...)
  local next_scene = self.scenes[name]
  if not next_scene then return end
  
  for i = #self.stack, 1, -1 do
    if self.stack[i].exit then 
      self.stack[i]:exit() 
    end
  end
  
  self.stack = {next_scene}
  if next_scene.init then next_scene:init(...) end
  
  if message_bus then
    message_bus:emit("scene_changed", {to=name})
  end
end

function scene:push(name, ...)
  local next_scene = self.scenes[name]
  if not next_scene then return end
  
  local current = self.stack[#self.stack]
  if current and current.pause then 
    current:pause() 
  end
  
  add(self.stack, next_scene)
  if next_scene.init then next_scene:init(...) end
end

function scene:pop()
  if #self.stack <= 1 then return end
  
  local old = deli(self.stack, #self.stack)
  if old.exit then old:exit() end
  
  local current = self.stack[#self.stack]
  if current and current.resume then 
    current:resume() 
  end
end

function scene:update()
  local current = self.stack[#self.stack]
  if current and current.update then 
    current:update() 
  end
end

function scene:draw()
  local current = self.stack[#self.stack]
  if current and current.draw then 
    current:draw() 
  end
end
