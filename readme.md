# Pico-8 Boilerplate

A minimal yet powerful boilerplate for Pico-8 projects, providing essential systems for building organized games: input management, scene/state handling, event messaging, and a flexible nested menu system.

## Core Systems

### Input Management
Map buttons to custom actions with context-aware handling. Input contexts automatically stack when menus open, allowing proper input isolation.

### Scene Management
Switch between major game sections (title screen, gameplay, game over) with automatic cleanup and initialization.

### State Management
Handle sub-states within scenes (player states, enemy AI states, game phases) with a lightweight finite state machine.

### Message Bus
Emit and subscribe to events across your game for decoupled communication between systems.

### Menu System
Create nested menus with dynamic labels, conditional enabling/disabling, and custom actions.

## Quick Start

### Basic Scene Structure

Each scene is a table with lifecycle methods:

```lua
my_scene = {}

function my_scene:init()
  -- called when scene becomes active
  -- setup variables, menus, input bindings
end

function my_scene:update()
  -- called every frame while active
  -- update game logic
end

function my_scene:draw()
  -- called every frame while active
  -- render graphics
end

function my_scene:exit()
  -- called when leaving scene
  -- cleanup input contexts, clear state
end
```

### Registering and Switching Scenes

```lua
function _init()
  scene:register('title', title_scene)
  scene:register('game', game_scene)
  scene:register('gameover', gameover_scene)
  scene:switch('title')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end
```

### Using State Management Within Scenes

The state manager is perfect for handling sub-states within a scene, like player states or game phases. States can include a `bindings` table that automatically manages input contexts when transitioning between states:

```lua
player_scene = {
  player_fsm = nil
}

function player_scene:init()
  -- define player states with automatic input handling
  local player_states = {
    idle = {
      init = function(data)
        data.anim = "idle"
        data.vx = 0
      end,

      -- bindings automatically bound when entering this state
      bindings = {
        [input.button.left] = function()
          self.player_fsm.data.direction = -1
          self.player_fsm:switch('walking')
        end,
        [input.button.right] = function()
          self.player_fsm.data.direction = 1
          self.player_fsm:switch('walking')
        end,
        [input.button.x] = function()
          self.player_fsm:switch('jumping')
        end
      },

      update = function(data)
        -- idle state logic (could check for fall, etc)
      end,

      draw = function(data)
        spr(1, data.x, data.y)
      end
    },

    walking = {
      init = function(data)
        data.anim = "walk"
        data.vx = data.direction * 2
        data.walking = true
      end,

      bindings = {
        [input.button.left] = function()
          self.player_fsm.data.direction = -1
          self.player_fsm.data.vx = -2
          self.player_fsm.data.walking = true
        end,
        [input.button.right] = function()
          self.player_fsm.data.direction = 1
          self.player_fsm.data.vx = 2
          self.player_fsm.data.walking = true
        end,
        [input.button.x] = function()
          self.player_fsm:switch('jumping')
        end
      },

      update = function(data)
        -- if no input this frame, stop walking
        if data.walking then
          data.x += data.vx
          data.walking = false  -- will be set true again by input if button held
        else
          data.vx = 0
          self.player_fsm:switch('idle')
        end
      end,

      draw = function(data)
        spr(2, data.x, data.y, 1, 1, data.direction == -1)
      end
    },

    jumping = {
      init = function(data)
        data.vy = -4
      end,

      -- jumping has no bindings - player can't control in air

      update = function(data)
        data.vy += 0.3
        data.y += data.vy

        if data.y >= 64 then
          data.y = 64
          self.player_fsm:switch('idle')
        end
      end,

      draw = function(data)
        spr(3, data.x, data.y)
      end
    }
  }

  -- create state manager
  self.player_fsm = state:new(player_states, 'idle')

  -- initialize player data
  self.player_fsm.data.x = 64
  self.player_fsm.data.y = 64
  self.player_fsm.data.vx = 0
  self.player_fsm.data.direction = 1
end

function player_scene:update()
  self.player_fsm:update()
end

function player_scene:draw()
  cls()
  self.player_fsm:draw()
end

function player_scene:exit()
  -- cleanup input contexts
  if self.player_fsm and self.player_fsm.current then
    local current_state = self.player_fsm.states[self.player_fsm.current]
    if current_state.bindings then
      input:pop()
    end
  end
  self.player_fsm = nil
end
```

### Another State Example: Game Phases

```lua
battle_scene = {
  phase_fsm = nil
}

function battle_scene:init()
  local phases = {
    player_turn = {
      init = function(data)
        data.menu:show()
      end,

      -- menu handles its own input, so no input table needed here

      update = function(data)
        data.menu:update()
      end,

      draw = function(data)
        print("your turn", 40, 10, 7)
        data.menu:draw()
      end
    },

    enemy_turn = {
      init = function(data)
        data.timer = 60
      end,

      -- player has no control during enemy turn

      update = function(data)
        data.timer -= 1
        if data.timer <= 0 then
          -- enemy attacks
          data.player_hp -= 10
          self.phase_fsm:switch('player_turn')
        end
      end,

      draw = function(data)
        print("enemy turn", 40, 10, 8)
      end
    }
  }

  self.phase_fsm = state:new(phases, 'player_turn')
  self.phase_fsm.data.player_hp = 100
  self.phase_fsm.data.menu = menu:new({
    {label="attack", action=function()
      -- do attack
      self.phase_fsm:switch('enemy_turn')
      return true
    end}
  }, 10, 10)
end

function battle_scene:update()
  self.phase_fsm:update()
end

function battle_scene:draw()
  cls()
  self.phase_fsm:draw()
  print("hp: "..self.phase_fsm.data.player_hp, 10, 120, 7)
end

function battle_scene:exit()
  if self.phase_fsm.data.menu.active then
    self.phase_fsm.data.menu:hide()
  end
  self.phase_fsm = nil
end
```

## Menu System

Create nested menus with dynamic content and conditional logic:

```lua
function game_scene:init()
  local m = self

  game_menu = menu:new({
    {label="resume", action=function() return true end},

    {label="options", sub_menu=menu:new({
      {label="volume", sub_menu=menu:new({
        {label="low", action=function() m.volume=1 end},
        {label="medium", action=function() m.volume=5 end},
        {label="high", action=function() m.volume=10 end}
      })},

      -- dynamic label
      {label=function()
        return "music: "..(m.music_on and "on" or "off")
      end, action=function()
        m.music_on = not m.music_on
      end},

      -- conditionally enabled
      {label="reset", action=function()
        m:reset_game()
      end, enabled=function()
        return m.can_reset
      end}
    })},

    {label="quit", action=function()
      scene:switch("title")
      return true
    end}
  }, 64, 64)

  -- bind menu to button
  input:bind({
    [input.button.x] = function()
      game_menu:show()
    end
  })
end

function game_scene:update()
  if game_menu.active then
    game_menu:update()
  end
end

function game_scene:draw()
  -- draw game

  if game_menu.active then
    game_menu:draw()
  end
end

function game_scene:exit()
  if game_menu.active then
    game_menu:hide()
    game_menu:close_parents()
  end
  input:clr()
end
```

## Input Management

### Binding Input

```lua
input:bind({
  [input.button.up] = function() player.y -= 1 end,
  [input.button.down] = function() player.y += 1 end,
  [input.button.x] = function() player:jump() end,
  [input.button.o] = function() player:shoot() end
})
```

### Input Stack

The input system automatically manages a stack when menus open, ensuring proper context isolation:

```lua
-- gameplay input active
game_menu:show()  -- automatically pushes new input context
-- now only menu input is active
game_menu:hide()  -- restores gameplay input
```

### Manual Stack Management

```lua
input:push()  -- save current bindings
input:bind({...})  -- new context
-- ... later ...
input:pop()  -- restore previous bindings
```

## Message Bus

Decouple systems with event-based communication:

```lua
-- subscribe to events
message_bus:subscribe("player_died", function(data)
  scene:switch("gameover")
end)

message_bus:subscribe("coin_collected", function(data)
  score += data.value
  sfx(3)
end)

-- emit events
message_bus:emit("player_died", {reason="fell"})
message_bus:emit("coin_collected", {value=10})
```

Built-in events:
- `scene_changed` - emitted when scenes switch
- `state_changed` - emitted when states transition
- `btn:up`, `btn:down`, `btn:left`, `btn:right`, `btn:x`, `btn:o` - button presses

## Advanced Scene Features

### Scene Stack (Push/Pop)

Use push/pop for temporary overlays that preserve the underlying scene:

```lua
scene:push('pause')  -- pauses current scene, shows pause menu
scene:pop()  -- returns to previous scene

-- optional pause/resume hooks
my_scene.pause = function(self)
  -- called when another scene is pushed on top
end

my_scene.resume = function(self)
  -- called when returning from a pushed scene
end
```

## Tips & Best Practices

1. **Always cleanup**: Clear input contexts in scene `exit()` methods
2. **Use state for substates**: Scenes for major transitions, states for internal logic
3. **Leverage the message bus**: Avoid tight coupling between systems
4. **Dynamic menu content**: Use functions for labels and enabled states
5. **Store scene data**: Use `self.` for scene variables, `data` table for state variables

## File Structure

```
bp.p8                    -- main cartridge
src/
  main.lua              -- entry point
  system/
    input.lua           -- input management
    menu.lua            -- menu system
    message_bus.lua     -- event bus
    scene.lua           -- scene manager
    state.lua           -- state machine
  scenes/
    game_scene.lua      -- your game scenes
```

## API Reference

### Scene Manager

- `scene:register(name, scene_table)` - register a scene
- `scene:switch(name, ...)` - switch to scene, call exit/init
- `scene:push(name, ...)` - push scene on stack, call pause/init
- `scene:pop()` - pop scene from stack, call exit/resume

### State Manager

- `state:new(states, initial)` - create new state machine
- `state:switch(name, ...)` - transition to new state (automatically handles input contexts)
- `state.data` - shared data table accessible in all states
- **State definition**: Each state can include an optional `bindings` table that will be automatically bound when entering that state and cleaned up when leaving

### Input Manager

- `input:bind(context)` - bind button handlers
- `input:push()` - save current context
- `input:pop()` - restore previous context
- `input:clr()` - clear all bindings

### Menu System

- `menu:new(items, x, y, opts)` - create menu
- `menu:show(parent)` - show menu
- `menu:hide()` - hide menu
- `menu:close_parents()` - close entire menu chain

### Message Bus

- `message_bus:subscribe(type, callback)` - listen for events
- `message_bus:emit(type, data)` - trigger events
- `message_bus:clr()` - clear all subscriptions
