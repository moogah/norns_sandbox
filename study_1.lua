-- many tomorrows
-- norns study 1

engine.name = "TestSine"

function init() 
  engine.hz(440)
  engine.amp(0.02)
  print("the end and the beginning they are the same")
end

function key(n,z)
  print("key " .. n .. " == " .. z)
end

function enc(n,d)
  print("encoder " .. n .. " == " .. d)
end