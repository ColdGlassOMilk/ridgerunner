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
      gold_m=0, gold_e=0, miners=0, pick_lvl=1, prestige=new_p
    })
  end})
end

function prestigescene:draw()
  cls()
  rectfill(6,16,122,112,1)
  rect(6,16,122,112,14)
  local function cprint(s,y,c) print(s,64-print(s,0,-100)/2,y,c) end
  if self.confirmed then
    cprint('pRESTIGING...', 60, 12)
    return
  end
  spr(9, 24, 26)
  print("pRESTIGE", 44, 30, 14)
  spr(9, 92, 26)
  cprint("wAVE "..gamescene:prestige_lvl_req().." rEACHED!", 44, 12)
  cprint("rESET pROGRESS FOR:", 56, 13)
  local curr_p = self.game.player.prestige or 0
  local curr_m = bignum:new(1):mul2(min(curr_p, 100))
  local new_m = bignum:new(1):mul2(min(curr_p + 1, 100))
  cprint("X"..new_m:tostr().." gOLD (aLL sOURCES)", 68, 11)
  cprint("cURRENT: lV "..curr_p.." (X"..curr_m:tostr().." gOLD)", 82, 13)
  cprint("❎ cONFIRM  🅾️ bACK", 98, 12)
end
