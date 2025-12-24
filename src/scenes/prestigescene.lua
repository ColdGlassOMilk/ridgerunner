-- prestige scene
prestigescene = {}

function prestigescene:init(game_ref)
  self.game, self.confirmed = game_ref, false
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
      gold_m=0, gold_e=0, miners=0, pick_lvl=1, prestige=new_p
    })
  end})
end

function prestigescene:draw()
  cls()
  rectfill(14,24,114,104,1)
  rect(14,24,114,104,14)
  local function cprint(s,y,c) print(s,64-print(s,0,-100)/2,y,c) end
  if self.confirmed then
    cprint('pRESTIGING...', 60, 12)
    return
  end
  spr(9, 24, 30)
  print("pRESTIGE", 44, 34, 14)
  spr(9, 92, 30)
  cprint("wAVE "..gamescene:prestige_lvl_req().." rEACHED!", 48, 12)
  print("rESET pROGRESS FOR:", 25, 58, 13)
  local curr_p = self.game.player.prestige or 0
  local curr_m = bignum:new(1):mul2(min(curr_p, 100))
  local new_m = bignum:new(1):mul2(min(curr_p + 1, 100))
  cprint("X"..new_m:tostr().." gOLD (aLL sOURCES)", 70, 11)
  print("cURRENT: lV "..curr_p.." (X"..curr_m:tostr().." gOLD)", 18, 82, 13)
  print("❎ cONFIRM  🅾️ bACK", 22, 94, 12)
end
