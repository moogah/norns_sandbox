-- clock test
--
-- adjust mul/div
-- with e2/e3
--
-- change clock settings
-- from parameters menu
--

engine.name = 'PolyPerc'

local blink_state_div = 0
local blink_state_beat = 0
local clock_mul = 1
local clock_div = 1
local task_id = nil

local function play_div()
  while true do
    clock.sync(clock_mul / clock_div)
    engine.hz(params:get("freq1"))
    
    blink_state_div = 1
    clock.sleep(0.1)
    blink_state_div = 0
  end
end

-- also to be invoked with clock.run
local function play_beat()
  while true do
    clock.sync(1)
    engine.hz(params:get("freq2"))
    
    blink_state_beat = 1
    clock.sleep(0.1)
    blink_state_beat = 0
  end
end

function init()
  params:add_number("freq1", "freq1", 1, 3000, 120)
  params:add_number("freq2", "freq2", 1, 3000, 60)

  clock.run(function()
    while true do
      clock.sleep(1/60)
      redraw()
    end
  end)
  
  -- store the coroutine (task) id
  -- for "play_div" so we can cancel it later
  task_id = clock.run(play_div)
  
  -- play_beat will be running constantly, so
  -- no need to save its task id
  clock.run(play_beat)
end

function enc(n, z)
  if n == 2 then
    clock_mul = math.min(20, math.max(1, clock_mul + z))
    
    -- re-run play task
    clock.cancel(task_id); blink_state_div = 0
    task_id = clock.run(play_div)
  elseif n == 3 then
    clock_div = math.min(20, math.max(1, clock_div + z))
    
    -- re-run play task
    clock.cancel(task_id); blink_state_div = 0
    task_id = clock.run(play_div)
  end
end

clock.transport.start = function()
  print('start callback')
end

clock.transport.stop = function()
  print('stop callback')
end

function key(n, z)
  if z == 1 and n == 2 then
    clock.internal.start()
  end
  if z == 1 and n == 3 then
    clock.internal.stop()
  end
end

function redraw()
  screen.clear()
  
  local beats = clock.get_beats()
  local qbeat = beats % 4

  --
  -- timeline
  --
  
  screen.level(1)
  
  screen.move(40, 20); screen.line(40, 36)
  screen.move(64, 20); screen.line(64, 36)
  screen.move(88, 20); screen.line(88, 36)
  
  screen.rect(16, 20, 96, 16)
  screen.stroke()
  
  --
  -- mul/div markers
  --
  
  screen.move(16, 24); screen.line(112, 24)
  screen.move(16, 32); screen.line(112, 32)
  screen.stroke()
  
  screen.level(15)

  local md = clock_mul / clock_div
  local min_screen_beat = math.floor(beats / 4) * 4
  local max_screen_beat = min_screen_beat + 4
  local marker_beat = math.ceil(min_screen_beat / md) * md
  local marker_qbeat = marker_beat % 4
  
  if marker_beat < max_screen_beat then
    repeat
      local screen_qbeat_x = marker_qbeat / 4.0 * 96 + 16
      screen.move(screen_qbeat_x, 24); screen.line(screen_qbeat_x, 32)
      screen.stroke()

      marker_qbeat = marker_qbeat + md
    until marker_qbeat > 4
  end
  
  --
  -- playhead
  --

  screen.level(15)

  local qbeat_x = qbeat / 4.0 * 96 + 16

  screen.move(qbeat_x, 20); screen.line(qbeat_x, 35)
  screen.stroke()

  --
  -- labels
  --

  screen.level(15)
  
  screen.move(64, 48)
  screen.text_center("mul/div - "..clock_mul.."/"..clock_div)

  screen.level(3)

  screen.move(0, 8)
  screen.text("clock: "..params:string("clock_source"))
  
  screen.move(128, 8)
  screen.text_right("bpm: "..string.format("%.0f", clock.get_tempo()))
  
  screen.move(0, 64)
  screen.text("beats: "..string.format("%.2f", beats))

  --
  -- blink indicators
  --

  if blink_state_div > 0 then
    screen.level(15)
    screen.rect(118, 20, 4, 4)
    screen.fill()
  end
  
  if blink_state_beat > 0 then
    screen.level(1)
    screen.rect(118, 32, 4, 4)
    screen.fill()
  end

  screen.update()
end