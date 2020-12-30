--[[

A simple lua script for togglable equalizer, dynamic range compressor and 
other filters yet to come.

Options:
preamp: Set preamp to avoid clipping.
bands : Add {freq = <frequency>, width = {'<type>', <value>}, gain = <gain>}
        to the bands for each modification of frequency, separated by comma.
	   
        freq : Set the filter’s central frequency in Hz.
        width: Set the bandwidth of filter
        type : Set method to specify bandwidth of filter.
               h  Hz
               q  Q-Factor 
               o  octave 
               s  slope
        value: Set the magnitude of the bandwidth
        gain : Set the required gain or attenuation in dB.

drc: Enable to compress the dynamic range of audio resulting in quieter parts 
     getting louder.

	 ratio    : Ratio by which the signal is changed.
	 attack   : Amount of ms the signal has to rise above the threshold before 
	            it triggers.
	 release  : Amount of ms the signal has to fall below the threshold before 
	            it is restored.
	 makeup   : Amount in dB the signal will be amplified after processing.
	 knee     : Curve the sharp knee around threshold dB to enter gain reduction
	            more softly. 
     threshold: Triggered if signal in dB rises above this level.
	 
eq_enabled : Start with equalizer enabled.
drc_enabled: Start with compressor enabled.

--]]

--[[ 

Personal settings for reducing treble sharpness in Beyerdynamic DT990 Pro

local preamp = -0.7
local bands = {
  {freq = 2300, width = {'q', 4.0}, gain = 1.0},
  {freq = 3000, width = {'q', 4.0}, gain = -1.0},
  {freq = 4390, width = {'q', 7.0}, gain = 1.0},
  {freq = 5840, width = {'q', 4.0}, gain = -8.2},
  {freq = 7300, width = {'q', 7.0}, gain = 2.5},
  {freq = 8220, width = {'q', 5.0}, gain = -11.0},
  {freq = 10420, width = {'q', 2.0}, gain = 1.3}
}

--]]

-- Settings --

local preamp = 0
local bands = {
  {freq = 64, width = {'o', 3.3}, gain = 0},   -- 20Hz - 200Hz
  {freq = 400, width = {'o', 2.0}, gain = 0},  -- 200Hz - 800Hz
  {freq = 1250, width = {'o', 1.3}, gain = 0}, -- 800Hz - 2kHz
  {freq = 2830, width = {'o', 1.0}, gain = 0}, -- 2kHz - 4kHz
  {freq = 5600, width = {'o', 1.0}, gain = 0}, -- 4kHz - 8kHz
  {freq = 12500, width = {'o', 1.3}, gain = 0} -- 8kHz - 20kHz
}

local drc = {
  threshold = -20,
  ratio = 2,
  attack = 20,
  release = 250,
  makeup = 8,
  knee = 3
}

local eq_enabled = true
local drc_enabled = false

-- Code --

local function push_preamp()
  if eq_enabled then 
    return 'no-osd af add lavfi=[volume=volume=' .. preamp .. 'dB:precision=fixed]'
  else
    return 'no-osd af remove lavfi=[volume=volume=' .. preamp .. 'dB:precision=fixed]'
  end
end

local function push_eq(filter)
  if eq_enabled then 
    return 'no-osd af add lavfi=[equalizer=f=' .. filter.freq .. ':width_type=' .. filter.width[1] .. ':w=' .. filter.width[2] .. ':g=' .. filter.gain .. ']'
  else
    return 'no-osd af remove lavfi=[equalizer=f=' .. filter.freq .. ':width_type=' .. filter.width[1] .. ':w=' .. filter.width[2] .. ':g=' .. filter.gain .. ']'
  end
end

local function push_drc()
  if drc_enabled then
    return 'no-osd af add acompressor=threshold=' .. drc.threshold .. 'dB:ratio=' .. drc.ratio .. ':attack=' .. drc.attack .. ':release=' .. drc.release .. ':makeup=' .. drc.makeup .. 'dB:knee=' .. drc.knee .. 'dB'
  else
    return 'no-osd af remove acompressor=threshold=' .. drc.threshold .. 'dB:ratio=' .. drc.ratio .. ':attack=' .. drc.attack .. ':release=' .. drc.release .. ':makeup=' .. drc.makeup .. 'dB:knee=' .. drc.knee .. 'dB'
  end
end

local function updateEQ()
  if preamp ~= 0 then mp.command(push_preamp()) end
  for i = 1, #bands do
    local f = bands[i]
    if f.gain ~= 0 then
	  mp.command(push_eq(f))
    end
  end
end

local function toggle_drc()
  drc_enabled = not drc_enabled
  mp.command(push_drc())
  if drc_enabled then mp.osd_message("Dynamic Range Compressor ON") else mp.osd_message("Dynamic Range Compressor OFF") end
end

local function toggle_eq()
  eq_enabled = not eq_enabled
  updateEQ()
  if eq_enabled then mp.osd_message("Equalizer ON") else mp.osd_message("Equalizer OFF") end
end

local function init_filters()
  if eq_enabled then 
    updateEQ()
  end
  if drc_enabled then 
    mp.command(push_drc(f))
  end
end

mp.add_key_binding(nil, "toggle-eq", toggle_eq)
mp.add_key_binding(nil, "toggle-drc", toggle_drc)

init_filters() -- Initializes the filter at start