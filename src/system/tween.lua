-- tween system

tween = {
  active = {}
}

-- easing functions (t = 0 to 1)
tween.ease = {
  -- linear = function(t) return t end,
  in_quad = function(t) return t * t end,
  out_quad = function(t) return 1 - (1 - t) * (1 - t) end,
  in_out_quad = function(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
  end,
  out_back = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
  end,
  -- in_back = function(t)
  --   local c1 = 1.70158
  --   local c3 = c1 + 1
  --   return c3 * t ^ 3 - c1 * t ^ 2
  -- end,
  out_elastic = function(t)
    if t == 0 or t == 1 then return t end
    return 2 ^ (-10 * t) * sin((t * 10 - 0.75) * 0.667) + 1
  end
}

-- create a new tween
-- target: table to modify
-- props: {key = end_value, ...}
-- duration: frames
-- opts: {ease, on_complete, delay}
function tween:new(target, props, duration, opts)
  opts = opts or {}
  local t = {
    target = target,
    props = {},
    duration = duration,
    elapsed = 0,
    delay = opts.delay or 0,
    ease = opts.ease or tween.ease.out_quad,
    on_complete = opts.on_complete,
    complete = false
  }

  -- store start and end values
  for k, v in pairs(props) do
    t.props[k] = {
      start = target[k],
      finish = v
    }
  end

  add(self.active, t)
  return t
end

-- update all active tweens
function tween:update()
  for t in all(self.active) do
    -- handle delay
    if t.delay > 0 then
      t.delay -= 1
    else
      t.elapsed += 1
      local progress = min(t.elapsed / t.duration, 1)
      local eased = t.ease(progress)

      -- update all properties
      for k, v in pairs(t.props) do
        t.target[k] = v.start + (v.finish - v.start) * eased
      end

      -- check completion
      if progress >= 1 then
        t.complete = true
        if t.on_complete then
          t.on_complete()
        end
        del(self.active, t)
      end
    end
  end
end

-- cancel a specific tween
function tween:cancel(t)
  del(self.active, t)
end

-- cancel all tweens on a target
function tween:cancel_all(target)
  for t in all(self.active) do
    if t.target == target then
      del(self.active, t)
    end
  end
end

-- clear all tweens
function tween:clear()
  self.active = {}
end

function tween:loop(target, props, duration, opts)
  opts = opts or {}
  local start_vals = {}
  for k, v in pairs(props) do
    start_vals[k] = target[k]
  end

  local function ping()
    tween:new(target, props, duration, {
      ease = opts.ease,
      on_complete = function()
        tween:new(target, start_vals, duration, {
          ease = opts.ease,
          on_complete = ping
        })
      end
    })
  end
  ping()
end
