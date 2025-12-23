-- prestige scene
prestigescene = {}

function prestigescene:init(game_ref)
  self.game, self.confirmed, self.anim_t = game_ref, false, 0
  input:bind({
    [input.button.x]=function() if not self.confirmed then self:confirm() end end,
    [input.button.o]=function() if not self.confirmed then scene:pop() end end
  })
end

function prestigescene:confirm()
  self.confirmed = true
  sfx(0, 3)
  local new_p = (self.game.player.prestige or 0) + 1
  tween:new(self, {anim_t=1}, 60, {on_complete=function()
    scene:pop()
    scene:switch('game', {
      hp=10, max_hp=10, atk=3, armor=0, spd=10, wave=1,
      gold_m=0, gold_e=0, miners=0, pick_lvl=1,
      prestige=new_p
    })
  end})
end

function prestigescene:update() self.anim_t += 0.02 end

function prestigescene:draw()
  cls()
  rectfill(16,30,116,102,0)
  rectfill(14,28,114,100,1)
  rect(14,28,114,100,6)

  if self.confirmed then
    print('pRESTIGING...', 64-print('pRESTIGING...',0,-100)/2, 60, 10)
    return
  end

  local function cprint(s,y,c) print(s,64-print(s,0,-100)/2,y,c) end
  cprint("★ pRESTIGE ★", 36, 10)
  cprint("wAVE "..gamescene:prestige_lvl_req().." rEACHED!", 45, 11)
  print("rESET pROGRESS FOR:", 25, 55, 6)

  local curr_p = self.game.player.prestige or 0
  local curr_m = shl(1, min(curr_p, 15))
  local new_m = shl(1, min(curr_p+1, 15))
  cprint("X"..new_m.." gOLD (aLL sOURCES)", 68, 10)
  print("cURRENT: ★"..curr_p.." (X"..curr_m.." gOLD)", 18, 80, 5)
  print("❎ cONFIRM  🅾️ bACK", 22, 92, 6)
end
