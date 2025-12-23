-- prestige scene
prestigescene = {draws_underneath=true, updates_underneath=false}

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
  local new_gm = (self.game.player.gold_mult or 0) + 1
  tween:new(self, {anim_t=1}, 60, {on_complete=function()
    scene:pop()
    scene:switch('game', {
      hp=10, max_hp=10, atk=3, armor=0, spd=10, wave=1,
      gold_m=0, gold_e=0, miners=0, pick_lvl=1,
      prestige=new_p, gold_mult=new_gm
    })
  end})
end

function prestigescene:update() self.anim_t += 0.02 end

function prestigescene:draw()
  cls()
  local px,py,pw,ph = 14,28,100,72
  rectfill(px+2,py+2,px+pw+2,py+ph+2,0)
  rectfill(px,py,px+pw,py+ph,1)
  rect(px,py,px+pw,py+ph,6)

  if self.confirmed then
    local msg="pRESTIGING..."
    print(msg, 64-print(msg,0,-100)/2, 60, 10)
    return
  end

  local function cprint(s,y,c) print(s,64-print(s,0,-100)/2,y,c) end
  cprint("★ pRESTIGE ★", py+6, 10)
  cprint("wAVE 50 rEACHED!", py+18, 11)
  print("rESET pROGRESS FOR:", px+6, py+32, 6)

  local curr_m = shl(1, self.game.player.gold_mult or 0)
  local new_m = curr_m * 2
  cprint("X"..new_m.." gOLD (aLL sOURCES)", py+44, 10)
  print("cURRENT: ★"..(self.game.player.prestige or 0).." (X"..curr_m.." gOLD)", px+6, py+ph-18, 5)
  print("❎ cONFIRM  🅾️ bACK", px+6, py+ph-8, 6)
end
