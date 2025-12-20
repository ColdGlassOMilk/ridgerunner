-- background mountains / sky
mountains = {}

function mountains:init()
  -- start time offset a bit so the mtns aren't all aligned
  t=5000

  self:bake_sky()
  self:bake_mountains()
end

function mountains:bake_sky()
  local sky_colors={{1,2},{2,8},{8,9},{9,10},{10,7}}
  local bayer={{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}

  -- bake sky as raw bytes (2 pixels per byte)
  -- 128 pixels wide = 64 bytes per row, 69 rows
  self.sky_data = {}

  for y=0,68 do
    local band = min(flr(y/14)+1,5)
    local c1,c2 = sky_colors[band][1],sky_colors[band][2]
    local th = (y%14)/14
    local by = bayer[y%4+1]

    for xb=0,63 do
      local x = xb*2
      local lo = (by[x%4+1]/16 < th) and c2 or c1
      local hi = (by[(x+1)%4+1]/16 < th) and c2 or c1
      self.sky_data[y*64+xb] = lo + hi*16
    end
  end
end

function mountains:bake_mountains()
  -- pre-calc peaks for 256px wide seamless loop
  self.mtns = {
    {speed=0.025, c1=1, c2=2, peaks={}},
    {speed=0.05, c1=2, c2=1, peaks={}},
    {speed=0.1, c1=1, c2=0, peaks={}},
    {speed=0.175, c1=0, c2=0, peaks={}},
  }

  local heights = {12,18,25,40}
  local bases = {55,50,45,38}
  local details = {0.3,0.5,0.7,1.0}

  for i,m in ipairs(self.mtns) do
    local ht,bs,dt = heights[i],bases[i],details[i]
    for x=0,255 do
      local h = sin(x*0.01)*ht*0.5
             + sin(x*0.023)*ht*0.3
             + sin(x*0.05)*ht*0.2
      if dt>0.5 then
        h += sin(x*0.1)*ht*0.1
      end
      m.peaks[x] = bs - h
    end
  end
end

function mountains:update()
  t+=1
end

function mountains:draw()
  -- blast sky directly to screen memory (0x6000)
  for i=0,68*64-1 do
    poke(0x6000+i, self.sky_data[i])
  end

  -- draw mountains with rectfill columns (way faster than pset loops)
  for _,m in ipairs(self.mtns) do
    local off = flr(t * m.speed) % 256
    local c1,c2 = m.c1, m.c2

    for x=0,127 do
      local peak = m.peaks[(x+off)%256]
      local py = flr(peak)

      -- single rectfill per column instead of pset loop
      -- use c1 as base, skip dithering for speed
      rectfill(x, py, x, 127, c1)
    end
  end

    -- scanlines (consider removing if still slow)
  -- for y=0,127,2 do
  --   line(0,y,127,y,128)
  -- end
end
