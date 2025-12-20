-- menu

menu = {}
menu.__index = menu

-- helper
function wrap(i, n)
  return ((i - 1) % n) + 1
end

-- Constructor
function menu:new(items, x, y, opts)
  opts = opts or {}
  local m = {
    x = x,
    y = y,
    draw_y = 128,  -- start off-screen
    items = items or {},
    active = false,
    visible = false,
    sel = 1,
    bgcol = opts.bgcol or 13,
    dropcol = opts.dropcol or 0,
    bordcol = opts.bordcol or 6,
    show_bg = opts.show_bg != false,
    show_border = opts.show_border != false,
    show_shadow = opts.show_shadow != false,
    closeable = opts.closeable != false
  }
  setmetatable(m, self)
  return m
end

-- Calculate menu dimensions
function menu:get_dimensions()
  local padding = 3
  local spacing = 2
  local font_h = 6

  local w = 0
  for item in all(self.items) do
    w = max(w, print(self:get_label(item), 0, -100))
  end
  local menu_w = w + padding * 2
  local menu_h = padding * 2 + font_h * #self.items + spacing * (#self.items - 1)

  return menu_w, menu_h
end

-- Show menu
function menu:show(parent)
  self.sel = 1
  self.active = true
  self.visible = true
  self.parent = parent
  if self.closeable then sfx(0, 3) end

  -- center if no position specified
  if not self.x or not self.y then
    local menu_w, menu_h = self:get_dimensions()
    self.x = self.x or (64 - menu_w / 2)
    self.y = self.y or (64 - menu_h / 2)
  end

  -- tween in from bottom
  tween:cancel_all(self)
  self.draw_y = 128
  tween:new(self, {draw_y = self.y}, 12, {
    ease = tween.ease.out_back
  })

  -- push input context and bind menu controls
  input:push()
  self:_bind_input()
end

-- internal: bind menu navigation
function menu:_bind_input()
  local bindings = {
    [input.button.up] = function() self:navigate(-1) end,
    [input.button.down] = function() self:navigate(1) end,
    [input.button.x] = function() self:select() end
  }

  if self.closeable then
    bindings[input.button.o] = function() self:hide() end
  end

  input:bind(bindings)
end

-- Hide menu
function menu:hide()
  if not self.active then return end
  self.active = false
  sfx(1, 3)
  input:pop()

  -- tween out to bottom
  tween:cancel_all(self)
  tween:new(self, {draw_y = 128}, 10, {
    ease = tween.ease.in_quad,
    on_complete = function()
      self.visible = false
    end
  })
end

-- Helper to check if item is enabled
function menu:is_enabled(item)
  if type(item.enabled) == "function" then
    return item.enabled()
  end
  return item.enabled != false
end

-- Helper to get item label
function menu:get_label(item)
  if type(item.label) == "function" then
    return item.label()
  end
  return item.label
end

-- Navigate menu
function menu:navigate(dir)
  self.sel = wrap(self.sel + dir, #self.items)
  sfx(2, 3)
end

-- Select item
function menu:select()
  local selected_item = self.items[self.sel]

  if not self:is_enabled(selected_item) then
    return
  end

  -- open sub-menu
  if selected_item.sub_menu then
    selected_item.sub_menu:show(self)
    return
  end

  -- execute action
  if selected_item and selected_item.action then
    local close_menu = selected_item.action()
    if close_menu then
      self:hide()
      self:close_parents()
    else
      sfx(0, 3)
    end
  end
end

-- Close parent menus recursively
function menu:close_parents()
  if self.parent and self.parent.active then
    self.parent:hide()
    self.parent:close_parents()
  end
end

-- Update (delegates to active sub-menu)
function menu:update()
  if not self.active then return end

  local selected_item = self.items[self.sel]
  if selected_item.sub_menu and selected_item.sub_menu.active then
    selected_item.sub_menu:update()
  end
end

-- Draw menu
function menu:draw()
  if not self.visible then return end

  local padding = 3
  local spacing = 2
  local font_h = 6

  local menu_w, menu_h = self:get_dimensions()

  -- use draw_y for animation, x stays fixed
  local draw_x = mid(0, self.x, 128 - menu_w - 2)
  local draw_y = self.draw_y

  -- shadow
  if self.show_shadow then
    rectfill(draw_x + 2, draw_y + 2, draw_x + menu_w + 2, draw_y + menu_h + 2, self.dropcol)
  end

  -- background
  if self.show_bg then
    rectfill(draw_x, draw_y, draw_x + menu_w, draw_y + menu_h, self.bgcol)
  end

  -- border
  if self.show_border then
    rect(draw_x, draw_y, draw_x + menu_w, draw_y + menu_h, self.bordcol)
  end

  -- items
  for i = 1, #self.items do
    local item_x = draw_x + padding
    local item_y = draw_y + padding + (font_h + spacing) * (i - 1)
    local item = self.items[i]
    local is_selected = i == self.sel
    local is_disabled = not self:is_enabled(item)
    local label = self:get_label(item)

    local shadow_col = is_selected and 0 or 1
    local text_col = is_disabled and 5 or (is_selected and 12 or 6)

    print(label, item_x + 1, item_y + 1, shadow_col)
    print(label, item_x, item_y, text_col)
  end

  -- sub-menu
  local selected_item = self.items[self.sel]
  if selected_item.sub_menu and selected_item.sub_menu.active then
    local sub = selected_item.sub_menu
    sub.x = draw_x + menu_w + 2
    sub.y = draw_y + (font_h + spacing) * (self.sel - 1)
    sub.draw_y = sub.y  -- sync draw_y for sub-menus
    spr(0, sub.x - 11, sub.y + padding)
    sub:draw()
  end
end
