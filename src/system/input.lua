-- input

input = {
  button = {
    left=0, right=1, up=2, down=3, o=4, x=5,
    hold = {left="hold_0", right="hold_1", up="hold_2", down="hold_3", o="hold_4", x="hold_5"}
  },
  stack = {},
  blocked = false,
  ch = 1 -- dedicated channel
}

local btn_names = {"left","right","up","down","o","x"}

function input:update()
  if self.blocked then return end
  for id=0,5 do
    if btnp(id) then message_bus:emit("press:"..btn_names[id+1], nil, self.ch) end
    if btn(id) then message_bus:emit("hold:"..btn_names[id+1], nil, self.ch) end
  end
end

function input:bind(context)
  for key, handler in pairs(context) do
    local event_key
    if type(key)=="string" and sub(key,1,5)=="hold_" then
      event_key = "hold:"..btn_names[tonum(sub(key,6))+1]
    else
      event_key = "press:"..btn_names[key+1]
    end
    message_bus:subscribe(event_key, handler, self.ch)
  end
end

function input:push()
  add(self.stack, message_bus.channels[self.ch] or {})
  message_bus.channels[self.ch] = {}
end

function input:pop()
  if #self.stack == 0 then return end
  message_bus.channels[self.ch] = deli(self.stack)
end

function input:clr()
  message_bus:clr(nil, self.ch)
end

function input:reset()
  message_bus.channels[self.ch] = {}
  self.stack = {}
  self.blocked = false
end

function input:down(b) return btn(b) end
function input:pressed(b) return btnp(b) end
