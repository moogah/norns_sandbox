local UI = require "ui"
local util = require "util"
local mu = require 'musicutil'

g = grid.connect()

local x_prev
local y_prev

g.key = function (x, y, z)
  if z == 1 then 
    x_prev = x
    y_prev = y
  end

  print("x: "..x.." y: "..y.." z: "..z)
  g:led(x,y,z*15)
  
  g:led(x+1,y,z*1)
  g:led(x-1,y,z*2)
  g:led(x,y+1,z*5)
  g:led(x,y-1,z*10)
  
  g:refresh()

end
