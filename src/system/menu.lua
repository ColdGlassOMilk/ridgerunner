-- menu

menu = {}
menu.__index = menu

function wrap(i, n) return ((i - 1) % n) + 1 end

function menu:new(items, x, y, opts)
  opts = opts or {}
  local m = {
    x=x, y=y, draw_y=128, items=items or {}, active=false, visible=false, sel=1,
    bgcol=opts.bgcol or 1, dropcol=opts.dropcol or 0, bordcol=opts.bordcol or 12,
    show_bg=opts.show_bg != false, show_border=opts.show_border != false,
    show_shadow=opts.show_shadow != false, closeable=opts.closeable != false,
    horizontal=opts.horizontal or false, icon_size=opts.icon_size or 8, spacing=opts.spacing or 2
  }
  return setmetatable(m, self)
end

function menu:get_dimensions()
  if self.horizontal then
    return #self.items * self.icon_size + (#self.items - 1) * self.spacing + 6, self.icon_size + 6
  end
  local w, fh = 0, 6
  for item in all(self.items) do w = max(w, print(self:get_label(item), 0, -100)) end
  return w + 6, 6 + fh * #self.items + self.spacing * (#self.items - 1)
end

function menu:show(parent)
  self.sel, self.active, self.visible, self.parent = 1, true, true, parent
  if self.closeable then sfx(0, 3) end
  if not self.x or not self.y then
    local mw, mh = self:get_dimensions()
    self.x, self.y = self.x or (64 - mw / 2), self.y or (64 - mh / 2)
  end
  tween:cancel_all(self)
  self.draw_y = 128
  tween:new(self, {draw_y = self.y}, 12, {ease = tween.ease.out_back})
  input:push()
  self:_bind_input()
end

function menu:_bind_input()
  local b = {}
  if self.horizontal then
    b[input.button.left] = function() self:navigate(-1) end
    b[input.button.right] = function() self:navigate(1) end
  else
    b[input.button.up] = function() self:navigate(-1) end
    b[input.button.down] = function() self:navigate(1) end
  end
  b[input.button.x] = function() self:select() end
  if self.closeable then b[input.button.o] = function() self:hide() end end
  input:bind(b)
end

function menu:hide()
  if not self.active then return end
  self.active = false
  sfx(1, 3)
  input:pop()
  tween:cancel_all(self)
  tween:new(self, {draw_y = 128}, 10, {ease = tween.ease.in_quad, on_complete = function() self.visible = false end})
end

function menu:is_enabled(item)
  if type(item.enabled) == "function" then return item.enabled() end
  return item.enabled != false
end

function menu:get_label(item)
  if type(item.label) == "function" then return item.label() end
  return item.label
end

function menu:navigate(dir) self.sel = wrap(self.sel + dir, #self.items) sfx(2, 3) end

function menu:select()
  local item = self.items[self.sel]
  if not self:is_enabled(item) then return end
  if item.sub_menu then
    if self.horizontal then
      local sub, sw, sh = item.sub_menu, item.sub_menu:get_dimensions()
      local ix, iy = self:get_icon_pos(self.sel)
      sub.x, sub.y = ix + self.icon_size / 2 - sw / 2, iy - sh - 4
    end
    item.sub_menu:show(self)
  elseif item.action then
    if item.action() then self:hide() self:close_parents() else sfx(0, 3) end
  end
end

function menu:close_parents()
  if self.parent and self.parent.active then self.parent:hide() self.parent:close_parents() end
end

function menu:update()
  if not self.active then return end
  local item = self.items[self.sel]
  if item.sub_menu and item.sub_menu.active then item.sub_menu:update() end
end

function menu:get_icon_pos(i)
  local mw = self:get_dimensions()
  local dx = mid(0, self.x, 128 - mw - 2)
  return dx + 3 + (i - 1) * (self.icon_size + self.spacing), self.draw_y + 3
end

function menu:draw()
  if not self.visible then return end
  local mw, mh = self:get_dimensions()
  local dx, dy = mid(0, self.x, 128 - mw - 2), self.draw_y

  if self.show_shadow then rectfill(dx + 2, dy + 2, dx + mw + 2, dy + mh + 2, self.dropcol) end
  if self.show_bg then rectfill(dx, dy, dx + mw, dy + mh, self.bgcol) end
  if self.show_border then rect(dx, dy, dx + mw, dy + mh, self.bordcol) end

  local item = self.items[self.sel]
  local sub_active = item.sub_menu and item.sub_menu.active

  if self.horizontal then
    for i = 1, #self.items do
      local it = self.items[i]
      local ix, iy = self:get_icon_pos(i)
      if i == self.sel then rectfill(ix - 1, iy - 1, ix + self.icon_size, iy + self.icon_size, 12) end
      if not self:is_enabled(it) then pal(7, 5) end
      spr(it.spr, ix, iy)
      pal()
    end
    if sub_active then
      local sub, sw, sh = item.sub_menu, item.sub_menu:get_dimensions()
      local ix, iy = self:get_icon_pos(self.sel)
      sub.x, sub.y = ix + self.icon_size / 2 - sw / 2, iy - sh - 4
      sub:draw()
    end
  else
    local fh = 6
    for i = 1, #self.items do
      local it = self.items[i]
      local ix, iy = dx + 3, dy + 3 + (fh + self.spacing) * (i - 1)
      local sel, dis = i == self.sel, not self:is_enabled(it)
      print(self:get_label(it), ix + 1, iy + 1, 0)
      print(self:get_label(it), ix, iy, dis and 13 or (sel and 12 or 7))
      -- if sel and not sub_active then spr(14, dx - 12 + sin(time()*3)*2, iy - 1, 1.5, 1.5) end -- hand
      if sel and not sub_active then spr(46, dx - 16 + sin(time()*3)*2, iy - 4, 1.9, 1.5) end -- carrot
    end
    if sub_active then
      local sub, fh = item.sub_menu, 6
      sub.x = dx + mw + 2
      sub.y = dy + (fh + self.spacing) * (self.sel - 1)
      sub.draw_y = sub.y
      spr(0, sub.x - 11, sub.y + 3)
      sub:draw()
    end
  end
end
