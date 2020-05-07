engine.name = "PolyPerc"

g = grid.connect()

m = midi.connect()

m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "cc" then
    handle_mft(data)
  end
end

g.key = function (x, y, z)
  if z==1 then engine.hz(100+x*4+y*64) end
  g:led(x,y,z*15)
  g:refresh()
end

function handle_mft(data)
  print(midi.to_msg(data).cc)
  print(midi.to_msg(data).val)
end