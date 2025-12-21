-- bignum: mantissa + exponent (e.g., 3200 = 3.2e3)
bignum={}
bignum.__index=bignum

function bignum:new(v)
  local b=setmetatable({m=0,e=0},self)
  if type(v)=="table" then b.m,b.e=v.m,v.e
  elseif type(v)=="number" then b.m,b.e=v,0 b:norm()
  elseif type(v)=="string" then
    local m,e=v:match("([%d%.]+)e(%d+)")
    if m then b.m,b.e=tonum(m),tonum(e)
    elseif #v<=4 then b.m=tonum(v)
    else b.m,b.e=tonum(sub(v,1,3).."."..sub(v,4,5)),#v-3 end
    b:norm()
  end
  return b
end

function bignum:norm()
  if self.m==0 then self.e=0 return self end
  local s=self.m<0 and -1 or 1
  self.m=abs(self.m)
  while self.m>=999.99 do self.m/=10 self.e+=1 end
  while self.m<1 and self.m>0 do self.m*=10 self.e-=1 end
  self.m*=s
  return self
end

function bignum:tonum()
  return self.e<=4 and self.m*10^self.e or 32767
end

function bignum:add(o)
  if type(o)=="number" then o=bignum:new(o) end
  local d=self.e-o.e
  if d>=6 then return self end
  if d<=-6 then self.m,self.e=o.m,o.e return self end
  if d>0 then self.m+=o.m/10^d
  elseif d<0 then self.m=self.m/10^-d+o.m self.e=o.e
  else self.m+=o.m end
  return self:norm()
end

function bignum:sub(o)
  if type(o)=="number" then o=bignum:new(o) end
  return self:add({m=-o.m,e=o.e})
end

function bignum:mul(o)
  if type(o)=="number" then self.m*=o
  else self.m*=o.m self.e+=o.e end
  return self:norm()
end

function bignum:cmp(o)
  if type(o)=="number" then o=bignum:new(o) end
  if self.m==0 and o.m==0 then return 0 end
  if self.m<=0 and o.m>0 then return -1 end
  if self.m>0 and o.m<=0 then return 1 end
  local s=self.m>0 and 1 or -1
  local sm,se,om,oe=abs(self.m),self.e,abs(o.m),o.e
  while sm>=10 do sm/=10 se+=1 end
  while sm<1 do sm*=10 se-=1 end
  while om>=10 do om/=10 oe+=1 end
  while om<1 do om*=10 oe-=1 end
  if se~=oe then return se>oe and s or -s end
  if sm~=om then return sm>om and s or -s end
  return 0
end

function bignum:gte(o) return self:cmp(o)>=0 end
function bignum:lte(o) return self:cmp(o)<=0 end
function bignum:gt(o) return self:cmp(o)>0 end
function bignum:lt(o) return self:cmp(o)<0 end
function bignum:eq(o) return self:cmp(o)==0 end
function bignum:clone() return bignum:new({m=self.m,e=self.e}) end

function bignum:tostr()
  local m,e,s=self.m,self.e,""
  if m<0 then s,m="-",-m end
  while m>=10 do m/=10 e+=1 end
  while m<1 and m>0 do m*=10 e-=1 end
  if e>=0 and e<=3 then return s..flr(m*10^e+.5) end
  local sx={"","k","m","b","t","q","Q","s","S","o","n","d"}
  local i=flr(e/3)+1
  if i>#sx then return s..flr(m*10)/10 .."e"..e end
  local d=m*10^(e%3)
  if d>=100 then return s..flr(d)..sx[i]
  elseif d>=10 then return s..flr(d*10)/10 ..sx[i]
  else return s..flr(d*100)/100 ..sx[i] end
end

function bignum:pack() return self.m,self.e end
function bignum:unpack(m,e) self.m,self.e=m or 0,e or 0 return self end
