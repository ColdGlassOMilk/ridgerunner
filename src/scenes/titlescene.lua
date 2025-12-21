-- title scene
titlescene = {}

function titlescene:init()
  main_menu = menu:new({
    {label='cONTINUE', action=function()
      local data = slot:load(1)
      if data then
        scene:switch('game', data)
      end
    end, enabled=function() return slot:exists(1) end},
    {label='nEW gAME', action=function() scene:switch('game') end},
    {label='lOAD', action=function() self.fsm:switch('load') end},
    {label='oPTIONS', action=function() self.fsm:switch('options') end},
    {label='cREDITS', action=function() self.fsm:switch('credits') end}
  }, nil, 75, {
    show_bg = false,
    show_border = false,
    show_shadow = false
  })

  load_menu = menu:new({
    {label=function()
      if slot:exists(1) then
        local data = slot:load(1)
        return 'sLOT 1 - wAVE ' .. data.wave
      end
      return 'sLOT 1 - eMPTY'
    end, action=function()
      local data = slot:load(1)
      if data then
        scene:switch('game', data)
      end
    end, enabled=function() return slot:exists(1) end},
    {label=function()
      if slot:exists(2) then
        local data = slot:load(2)
        return 'sLOT 2 - wAVE ' .. data.wave
      end
      return 'sLOT 2 - eMPTY'
    end, action=function()
      local data = slot:load(2)
      if data then
        scene:switch('game', data)
      end
    end, enabled=function() return slot:exists(2) end},
    {label=function()
      if slot:exists(3) then
        local data = slot:load(3)
        return 'sLOT 3 - wAVE ' .. data.wave
      end
      return 'sLOT 3 - eMPTY'
    end, action=function()
      local data = slot:load(3)
      if data then
        scene:switch('game', data)
      end
    end, enabled=function() return slot:exists(3) end},
    {label='dELETE', sub_menu=menu:new({
      {label='sLOT 1', enabled=function() return slot:exists(1) end, sub_menu=menu:new({
        {label='cONFIRM?', action=function() return slot:delete(1) end}
      })},
      {label='sLOT 2', enabled=function() return slot:exists(2) end, sub_menu=menu:new({
        {label='cONFIRM?', action=function() return slot:delete(2) end}
      })},
      {label='sLOT 3', enabled=function() return slot:exists(3) end, sub_menu=menu:new({
        {label='cONFIRM?', action=function() return slot:delete(3) end}
      })},
    })}
  }, nil, 75, {
    show_bg = false,
    show_border = false,
    show_shadow = false
  })

  options_menu = menu:new({
    {label=function()
      return 'mUSIC: ' .. (options.music_on and '\#3oN ♪\#7' or '\#5oFF\#7')
    end, action=function()
      options.music_on = not options.music_on
      app:save_options(options)
      if options.music_on then
        music(0)
      else
        music(-1, 0)
      end
    end},
    {label='rESET dEFAULTS', action=function()
      if not options.music_on then music(0) end
      slot:reset_options()
      options = app:copy_flags_defaults()
    end}
  }, nil, 75, {
    show_bg = false,
    show_border = false,
    show_shadow = false
  })

  self.fsm = state:new({
    splash = {
      bindings = {
        [input.button.x] = function()
          self.fsm:switch('main')
          if not slot:exists(1) then main_menu.sel = 2 end
        end
      },
      init = function()
        self.cont_y = 101
        tween:loop(self, {cont_y = 96}, 30, {ease = tween.ease.in_out_quad})
      end,
      draw = function()
        local w = print('print ❎ to begin', 0, -100)
        -- print('press ❎ to begin', 63-w/2, 100, 1)
        print('press ❎ to begin', 63-w/2, self.cont_y, 2)
      end,
      exit = function()
        tween:clear()
      end
    },
    main = {
      init = function()
        main_menu:show()
      end,
      update = function()
        if main_menu.active then
          main_menu:update()
        else
          main_menu:hide()
          self.fsm:switch('splash')
        end
      end,
      draw = function()
        main_menu:draw()
      end
    },
    load = {
      init = function()
        load_menu:show()
      end,
      update = function()
        if load_menu.active then
          load_menu:update()
        else
          load_menu:hide()
          self.fsm:switch('main')
          main_menu.sel = 3
        end
      end,
      draw = function()
        load_menu:draw()
      end
    },
    options = {
      init = function()
        options_menu:show()
      end,
      update = function()
        if options_menu.active then
          options_menu:update()
        else
          options_menu:hide()
          self.fsm:switch('main')
          main_menu.sel = 4
        end
      end,
      draw = function()
        options_menu:draw()
      end
    },
    credits = {
      bindings = {
        [input.button.o] = function()
          self.fsm:switch('main')
          main_menu.sel = 5
        end,
        [input.button.x] = function()
          self.fsm:switch('main')
          main_menu.sel = 5
        end
      },
      draw = function()
        print('\n\npROGRAMMING & dESIGN:\nnICK bRABANT\n\nmUSIC:\nfETTUCCINI')
      end
    }
  }, 'splash')

  -- start music based on saved option
  if options.music_on then
    music(0)
  end
end

function titlescene:update()
  mountains:update()
  self.fsm:update(self)
end

function titlescene:draw()
  cls()
  mountains:draw()
  local w = print('rIDGE rUNNER', 0, -100)
  print('rIDGE rUNNER', 63-w/2, 30, 7)
  self.fsm:draw(self)
end
