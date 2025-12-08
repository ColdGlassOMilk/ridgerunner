# Pico-8 Boilerplate

A minimal boilerplate for Pico-8 projects, providing input management, scene/state handling, a message bus, and a flexible, nested menu system.

## Features

- **Input Management** – Map buttons to custom actions with context-aware handling.
- **Scene/State Management** – Switch between game scenes or states easily.
- **Message Bus** – Dispatch and listen for events across scenes.
- **Customizable Menu System** – Nested menus with dynamic enabling/disabling and actions.

## Quick Start

### 1. Create a Scene
Each scene is a Lua table with `init()`, `update()`, `draw()`, and `exit()` functions:

```lua
game_scene = {}

function game_scene:init()
    -- initialize variables, menus, and input bindings
end

function game_scene:update()
    -- update game logic and menu
end

function game_scene:draw()
    -- draw scene and menu
end

function game_scene:exit()
    -- cleanup input or other resources
end
```

### 2. Register a Scene
Use the scene manager to `switch()` between scenes. Also supports `push()` and `pop()` to retain state.

```lua
-- main

function _init()
  scene:register('game', game_scene)
  scene:switch('game')
end

function _update()
  input:update()
  scene:update()
end

function _draw()
  scene:draw()
end

```

### 3. Setup Menus & Input Bindings
Menus can be nested, have dynamic enabled states, and perform actions:

```lua
game_menu = menu:new({
  { label="new game", action=function() scene:switch("game") end },
  { label="options", sub_menu=menu:new({
      { label="bg color", action=function() bgcol=1 end }
  })},
  { label="close", action=function() return true end }
}, x, y)
```

Use `input.bind` to define the input context on a per scene/state basis.
```lua
input:bind({
  [input.button.x] = function() game_menu:show() end
})
```

### 4. Cleanup
```lua
function game_scene:exit()
  -- clean up input contexts
  if game_menu.active then
    game_menu:hide()
    game_menu:close_parents()
  end
  input:clr()
end
```
