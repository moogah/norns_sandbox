
local UI = require "ui"
local util = require "util"
local mu = require 'musicutil'
local bclk = require 'beatclock'
local clk = bclk.new()

g = grid.connect()

m = midi.connect(1)

m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "cc" then
    handle_mft(data)
  end
  
  clk:process_midi(data)
end

g.key = function (x, y, z)
  g:led(x,y,z*15)
  g:refresh()
end

function handle_mft(data)
  cc = midi.to_msg(data).cc
  --print(cc)
  val = midi.to_msg(data).val
  --print(val)
  
  if cc == 12 then 
    -- snap the incoming value to our generated scale (will have odd effects with midi-to-midi mapping and the voct mapping below don't jive)
    snapped = mu.snap_note_to_array(val, notes)
    print(snapped)


    -- convert our snapped midi notes to voct
    -- min incoming midi value is 12, max value in our generated scale is 108
    -- mapped to octave 1 through 8 in voct
    v_oct = util.linlin(12, 108, 1, 9, snapped)
    print(v_oct)
    

    crow.ii.ansible.cv(3, v_oct) 
  end
end

cv = {
    volts = {4, 1, 0, 0},
    slew = {0, 0, 0, 0},
    fine_mode = false,
    pulse_time = {5, 5, 5, 5}
}

-- create note numbers for 8 octaves of a major scale starting on note 12
-- https://monome.org/norns/modules/MusicUtil.html#generate_scale
-- print(#notes) shows 57 (7*7+8) ((octaves - 1) * (octaves - 1) + octaves)
notes = mu.generate_scale(12, "minor", 8)


function init()
    crow.ii.pullup(true)

    -- initialize cv, slew, and pulse time  across all four channels
    for i = 0, 3 do
      crow.ii.ansible.cv(i, cv.volts[i+1])
    end
    
    -- set the bottom left knob to the mid position
    m:cc(12, 64, 1)
    
    -- set the bottom left light to on
    -- 0 will set color to off state (set in MF Utility, 'off' can have a color other than black)
    -- values 1-126 choose a color
    -- 127 will set color to on state (set in MF Utility)
    -- works in conjunction with animation settings
    m:cc(12, 1, 2)
    
    -- set encoder 12's light to pulse slowly
    -- 0 will stop animation
    -- 1 - 8 are gate/toggles, toggled every: [4, 2, 1, 1/2, 1/4, 1/8, 1/6, 1/32] beat 
    -- 9 - 16 are pulse (fade) cycle time [16, 8, 4, 2, 1, 1/2, 1/4, 1/8] beats
    m:cc(12, 12, 3)
    
    -- set to bank 1
    m:note_off(0, 0, 4) -- this doesn't appear necessary, but the MFT will send this back when you switch
    m:note_on(0, 127, 4) -- velocity of 127 is necessary
    
    -- convert a 0-127 value to 0-10 (result is 5)
    --print(util.linlin(0, 127, 0, 10, 63.5))

    --tab.print(notes)
    --print(#notes)
    
    -- create a control spec with a range of 50-5000, exponential scaling and a default of 555
    cspec = controlspec.new(50,5000,'exp',0,555,'hz')
    tab.print(cspec)
    
    -- use a control spec as part of a param
    params:add_control("cutoff","cutoff",controlspec.new(50,5000,'exp',0,555,'hz'))
    params:get("cutoff") -- prints default of 555
    params:set("cutoff", 440) -- normally accepts units in it's output scale
    params:get("cutoff")
    params:set_raw("cutoff", 1) -- set_raw takes 0-1 and outputs the mapped value
    params:get("cutoff")
    
    -- use params instead of mapping the midi manually
    -- this mapping means we're bound to the output range of crow
    params:add_control("voct", "voct", controlspec.new(0, 10, 'lin', 0.5, 2, 'voct'))
    params:set_action("voct", function(x) crow.ii.ansible.cv(3, x) end)
    
    -- need a way of mapping the return midi message any time the param is updated.
    -- can be manually added to each above line, easy enough
    -- but the midi mapping should contain the cc# (and device id?) for automagic updates
    -- search for pmap
    -- code for the params menu page https://github.com/monome/norns/blob/master/lua/core/menu/params.lua
    -- controlspec id assignment to midi device info? https://github.com/monome/norns/blob/master/lua/core/pmap.lua#L39
    --tab.print(norns.pmap)
    --tab.print(norns.pmap.data.voct) bingo!!!
    -- that table contains all the info we need to update the cc data on mft.  keyed by the name (index) of the param.
    -- so in set_action, call a mft update handler with ie: redraw_mft(norns.pmap.data.voct)
    
    -- uses the id of a controlspec to access the cc and ch values from norns.pmap, sends cc back to mft
    -- m:cc(norns.pmap.data.voct.cc, 60, norns.pmap.data.voct.ch) -- instead of 60 params:get_raw("voct")*127
    -- check if pmap exists with norns.pmap.data.pmap_name == nil
    
    -- remap to midi values
    midival = params:get_raw("cutoff") * 127
    
    
    print(cspec:map(.5))
    print(cspec:unmap(500))
end


