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
    closeable = opts.closeable != false,
    horizontal = opts.horizontal or false,
    icon_size = opts.icon_size or 8,
    spacing = opts.spacing or 2
  }
  setmetatable(m, self)
  return m
end

-- Calculate menu dimensions
function menu:get_dimensions()
  if self.horizontal then
    local w = #self.items * self.icon_size + (#self.items - 1) * self.spacing + 6
    local h = self.icon_size + 6
    return w, h
  else
    local font_h = 6
    local w = 0
    for item in all(self.items) do
      w = max(w, print(self:get_label(item), 0, -100))
    end
    local menu_w = w + 6
    local menu_h = 6 + font_h * #self.items + self.spacing * (#self.items - 1)
    return menu_w, menu_h
  end
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
  local bindings = {}

  if self.horizontal then
    bindings[input.button.left] = function() self:navigate(-1) end
    bindings[input.button.right] = function() self:navigate(1) end
  else
    bindings[input.button.up] = function() self:navigate(-1) end
    bindings[input.button.down] = function() self:navigate(1) end
  end

  bindings[input.button.x] = function() self:select() end

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
    -- position sub-menu before showing
    if self.horizontal then
      local sub = selected_item.sub_menu
      local sub_w, sub_h = sub:get_dimensions()
      local ix, iy = self:get_icon_pos(self.sel)
      sub.x = ix + self.icon_size / 2 - sub_w / 2
      sub.y = iy - sub_h - 4
    end
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

-- Get icon position for horizontal menus
function menu:get_icon_pos(i)
  local padding = 3
  local menu_w, menu_h = self:get_dimensions()
  local draw_x = mid(0, self.x, 128 - menu_w - 2)
  local ix = draw_x + padding + (i - 1) * (self.icon_size + self.spacing)
  local iy = self.draw_y + padding
  return ix, iy
end

-- Draw menu
function menu:draw()
  if not self.visible then return end

  local padding = 3
  local menu_w, menu_h = self:get_dimensions()

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

  if self.horizontal then
    -- horizontal icon layout
    for i = 1, #self.items do
      local item = self.items[i]
      local ix, iy = self:get_icon_pos(i)
      local is_selected = i == self.sel
      local is_disabled = not self:is_enabled(item)

      -- selection highlight
      if is_selected then
        rectfill(ix - 1, iy - 1, ix + self.icon_size, iy + self.icon_size, 12)
      end

      -- sprite (use pal for disabled look)
      if is_disabled then
        pal(7, 5)
      end
      spr(item.spr, ix, iy)
      pal()
    end

    -- draw sub-menu for horizontal
    local selected_item = self.items[self.sel]
    if selected_item.sub_menu and selected_item.sub_menu.active then
      local sub = selected_item.sub_menu
      local sub_w, sub_h = sub:get_dimensions()
      local ix, iy = self:get_icon_pos(self.sel)
      sub.x = ix + self.icon_size / 2 - sub_w / 2
      sub.y = iy - sub_h - 4
      sub:draw()
    end
  else
    -- vertical text layout
    local font_h = 6
    for i = 1, #self.items do
      local item_x = draw_x + padding
      local item_y = draw_y + padding + (font_h + self.spacing) * (i - 1)
      local item = self.items[i]
      local is_selected = i == self.sel
      local is_disabled = not self:is_enabled(item)
      local label = self:get_label(item)

      local shadow_col = is_selected and 0 or 1
      local text_col = is_disabled and 5 or (is_selected and 12 or 6)

      print(label, item_x + 1, item_y + 1, shadow_col)
      print(label, item_x, item_y, text_col)
    end

    -- draw sub-menu for vertical
    local selected_item = self.items[self.sel]
    if selected_item.sub_menu and selected_item.sub_menu.active then
      local sub = selected_item.sub_menu
      local font_h = 6
      sub.x = draw_x + menu_w + 2
      sub.y = draw_y + (font_h + self.spacing) * (self.sel - 1)
      sub.draw_y = sub.y
      spr(0, sub.x - 11, sub.y + padding)
      sub:draw()
    end
  end
end
