-- pause overlay scene

pause_scene = {
  -- these flags tell the scene manager how to handle this overlay
  draws_underneath = true,    -- game scene still draws
  updates_underneath = false  -- game scene pauses updating
}

function pause_scene:init()
  input:bind({
    [input.button.x] = function()
      scene:pop()  -- unpause
    end,
    [input.button.o] = function()
      scene:pop()  -- unpause
    end
  })
end

function pause_scene:update()
  -- pause menu logic here
end

function pause_scene:draw()
  -- dim the background
  for i = 0, 15 do
    pal(i, 0)
  end
  -- rectfill(0, 0, 127, 127, 0)
  pal()

  -- semi-transparent overlay effect (dither)
  for y = 0, 127, 2 do
    for x = (y/2) % 2, 127, 2 do
      pset(x, y, 0)
    end
  end

  -- pause text
  local txt = "paused"
  local w = print(txt, 0, -100)
  print(txt, 64 - w/2 + 1, 61, 0)
  print(txt, 64 - w/2, 60, 7)

  print("❎/🅾️ resume", 40, 80, 6)
end

function pause_scene:exit()
  -- input context is automatically popped by scene:pop()
end
