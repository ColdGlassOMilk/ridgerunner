-- scene manager

scene = {
  stack = {},
  scenes = {}
}

function scene:register(name, scn)
  self.scenes[name] = scn
end

-- completely switch to a new scene (clears stack)
function scene:switch(name, ...)
  local next_scene = self.scenes[name]
  if not next_scene then return end

  -- exit all current scenes
  for i = #self.stack, 1, -1 do
    local s = self.stack[i]
    if s.exit then s:exit() end
  end

  -- reset input for clean slate
  input:reset()

  self.stack = {next_scene}
  if next_scene.init then next_scene:init(...) end

  message_bus:emit("scene_changed", {to = name})
end

-- push a scene on top (for overlays, pause menus, etc)
function scene:push(name, ...)
  local next_scene = self.scenes[name]
  if not next_scene then return end

  local current = self.stack[#self.stack]
  if current and current.pause then
    current:pause()
  end

  -- push input context so overlay gets fresh bindings
  input:push()

  add(self.stack, next_scene)
  if next_scene.init then next_scene:init(...) end

  message_bus:emit("scene_pushed", {name = name})
end

-- pop the top scene
function scene:pop()
  if #self.stack <= 1 then return end

  local old = deli(self.stack)
  if old.exit then old:exit() end

  -- restore previous input context
  input:pop()

  local current = self.stack[#self.stack]
  if current and current.resume then
    current:resume()
  end

  message_bus:emit("scene_popped", {})
end

function scene:update()
  -- update from bottom to top, respecting flags
  for i = 1, #self.stack do
    local s = self.stack[i]
    local next_scene = self.stack[i + 1]

    -- update if: we're the top scene, OR the scene above us allows updates underneath
    local is_top = (i == #self.stack)
    local scene_above_allows = next_scene and next_scene.updates_underneath

    if is_top or scene_above_allows then
      if s.update then s:update() end
    end
  end
end

function scene:draw()
  -- find the lowest scene we need to draw
  local draw_from = #self.stack

  for i = #self.stack, 1, -1 do
    draw_from = i
    local s = self.stack[i]
    -- stop going down if this scene doesn't draw underneath
    if not s.draws_underneath then
      break
    end
  end

  -- draw from bottom-most visible scene to top
  for i = draw_from, #self.stack do
    local s = self.stack[i]
    if s.draw then s:draw() end
  end
end

-- get current (top) scene
function scene:current()
  return self.stack[#self.stack]
end

-- get scene by index (1 = bottom)
function scene:get(i)
  return self.stack[i]
end

-- check how many scenes are stacked
function scene:depth()
  return #self.stack
end
