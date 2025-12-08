# Pico-8 Boilerplate
A minimal boilerplate for Pico-8 projects with input management, scene handling, nested menus, and save/load functionality.

## Features
- **Input Management** – Bind buttons to actions with context switching
- **Scene Management** – Switch between game scenes with `switch()`, `push()`, and `pop()`
- **Message Bus** – Event system for decoupled communication
- **Menu System** – Nested menus with dynamic states and actions
- **Slot System** – Save and load game data across 3 persistent slots

## Quick Start

### Create a Scene
```lua
my_scene = {}

function my_scene:init()
  -- setup
end

function my_scene:update()
  -- game logic
end

function my_scene:draw()
  -- rendering
end

function my_scene:exit()
  -- cleanup
end
```

### Register & Switch Scenes
```lua
function _init()
  scene:register('game', my_scene)
  scene:switch('game')
end
```

### Create Menus
```lua
my_menu = menu:new({
  {label="start", action=function() scene:switch("game") end},
  {label="options", sub_menu=menu:new({
    {label="sound", action=function() sfx_on=true end}
  })},
  {label="quit", action=function() return true end}
}, x, y)
```

### Bind Input
If using the **state system**, define a `bindings` table in your state and it's automatically managed:
```lua
my_state = {
  bindings = {
    [input.button.x] = function() my_menu:show() end
  }
}
```

For **manual control** in scenes, use `input:bind()` in `init()` and `input:clr()` in `exit()`:
```lua
input:bind({
  [input.button.x] = function() my_menu:show() end,
  [input.button.o] = function() my_menu:hide() end,
  [input.button.hold.left] = function() player.x -= 1 end
})
```

Use `input.button.hold.*` for continuous input like movement. Regular buttons trigger on press.

Available buttons: `left`, `right`, `up`, `down`, `o`, `x`

### Use States Within Scenes
For complex scenes with multiple states (e.g., playing, paused, game over):
```lua
function my_scene:init()
  self.fsm = state:new({
    playing = playing_state,
    paused = paused_state
  }, 'playing')
end

function my_scene:update()
  self.fsm:update()
end
```

### Save & Load System
Initialize the slot system with your save data structure:
```lua
function _init()
  -- define what data to save (up to 18 values per slot)
  slot:init("my_game_v1", {"score", "level", "lives", "flags"})

  scene:register('game', my_scene)
  scene:switch('game')
end
```

Save and load game data:
```lua
-- save to slot 1
function save_game()
  slot:save(1, {
    score = player_score,
    level = current_level,
    lives = player_lives,
    flags = game_flags
  })
end

-- load from slot 1
function load_game()
  local data = slot:load(1)
  if data then
    player_score = data.score
    current_level = data.level
    player_lives = data.lives
    game_flags = data.flags
  end
end

-- check if slot exists
if slot:exists(1) then
  print("slot 1 has save data")
  print("saved at: "..slot:timestamp(1))
end

-- delete a slot
slot:delete(2)
```

**Slot Limitations:**
- 3 slots available (configurable via `slot.slots`)
- 18 values per slot maximum
- Only numbers supported (integers, decimals, or 0/1 for booleans)

### Message Bus
Send and receive events across your game:
```lua
-- subscribe
message_bus:subscribe('player_died', function(data)
  lives = lives - 1
end)

-- emit
message_bus:emit('player_died', {reason='fell'})
```

### Cleanup on Exit
```lua
function my_scene:exit()
  if my_menu.active then
    my_menu:hide()
    my_menu:close_parents()
  end
  input:clr()
end
```
