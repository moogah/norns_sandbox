local util = require "util"
local mu = require 'musicutil'

local g = grid.connect()
m = midi.connect(1)

function init() 
  clock.run(metronome)
end

local pattern = {
  {
    step_time = 1,
  }, 
  {
    step_time = 1,
  },  
  {
    step_time = 1,
  },  
  {
    step_time = 1,
  }
}
-- divisor in clock sync should(?) equal the number of sync calls
function metronome()
  while true do
    for i = 1, #pattern do
      g:led(1, 1, get_led_value(1, i))
      g:led(2, 1, get_led_value(2, i))
      g:led(3, 1, get_led_value(3, i))
      g:led(4, 1, get_led_value(4, i))
      g:refresh()
      clock.sync(pattern[i].step_time / #pattern)
    end
  end
end

function get_led_value(led, step)
  if led == step then
    return 15
  else
    return 0
  end
end

function echo(x, y)
  print("echoing")
  clock.sync(1)
  
  g:led(x+5, y, 15)
  g:refresh()
  clock.sleep(.2)
  g:led(x+5, y, 0)
  g:refresh()
  
  print("echo'd")
end

g.key = function (x, y, z)
  if z == 1 then 
    x_prev = x
    y_prev = y
  end

  print("x: "..x.." y: "..y.." z: "..z)
  g:led(x,y,z*15)
  
  g:refresh()

  if z == 1 then
   clock.run(echo, x, y)
  end

end