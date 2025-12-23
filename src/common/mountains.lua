-- background mountains / sky
mountains = {}

function mountains:init()
  t=5000
  self:bake_sky()
  self:bake_mountains()
end

function mountains:bake_sky()
  local sc={{1,2},{2,8},{8,9},{9,10},{10,7}}
  local by={{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}
  self.sky_data={}
  for y=0,68 do
    local b=min(flr(y/14)+1,5)
    local c1,c2,th=sc[b][1],sc[b][2],(y%14)/14
    local r=by[y%4+1]
    for xb=0,63 do
      local x=xb*2
      self.sky_data[y*64+xb]=(r[x%4+1]/16<th and c2 or c1)+(r[(x+1)%4+1]/16<th and c2 or c1)*16
    end
  end
end

function mountains:bake_mountains()
  self.mtns={
    {speed=0.025,c=1,peaks={}},
    {speed=0.06,c=2,peaks={}},
    {speed=0.12,c=0,peaks={}}
  }
  local ht,bs={14,22,35},{54,48,40}
  for i,m in ipairs(self.mtns) do
    local h,b=ht[i],bs[i]
    -- use fewer, lower frequency waves for smoother hills
    for x=0,255 do
      m.peaks[x]=b-sin(x*0.008)*h*0.6-sin(x*0.019)*h*0.4
    end
    -- multi-pass smoothing
    for p=1,3 do
      for x=1,254 do
        m.peaks[x]=(m.peaks[x-1]+m.peaks[x]+m.peaks[x+1])/3
      end
    end
  end
end

function mountains:update()
  t+=2
end

function mountains:draw()
  for i=0,68*64-1 do poke(0x6000+i,self.sky_data[i]) end
  for _,m in ipairs(self.mtns) do
    local off=flr(t*m.speed)%256
    for x=0,127 do
      rectfill(x,m.peaks[(x+off)%256],x,127,m.c)
    end
  end
end

-- get peak height at screen x (for title text)
function mountains:peak_at(x)
  local m=self.mtns[3]
  local off=flr(t*m.speed)%256
  return m.peaks[(x+off)%256]
end
