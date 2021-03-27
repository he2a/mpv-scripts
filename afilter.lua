--[[

A simple lua script for togglable equalizer, dynamic range compressor, stereo downmix and 
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
		
Basic example of 6 band blank equalizer.
preamp = 0
bands = {
  {freq = 64, width = {'o', 3.3}, gain = 0},   -- 20Hz - 200Hz
  {freq = 400, width = {'o', 2.0}, gain = 0},  -- 200Hz - 800Hz
  {freq = 1250, width = {'o', 1.3}, gain = 0}, -- 800Hz - 2kHz
  {freq = 2830, width = {'o', 1.0}, gain = 0}, -- 2kHz - 4kHz
  {freq = 5600, width = {'o', 1.0}, gain = 0}, -- 4kHz - 8kHz
  {freq = 12500, width = {'o', 1.3}, gain = 0} -- 8kHz - 20kHz
}

drc: Enable to compress the dynamic range of audio.

	 ratio    : Ratio by which the signal is changed.
	 attack   : Amount in ms the signal has to rise above the threshold before 
	            it triggers.
	 release  : Amount in ms the signal has to fall below the threshold before 
	            it is restored.
	 makeup   : Amount in dB the signal will be amplified after processing.
	 knee     : Curve the sharp knee around threshold dB to enter gain reduction
	            more softly. 
     threshold: Triggered if signal in dB rises above this level.
	 
nor: Enable to dynamically normalize the loudness of audio.

	 frame    : Size of audio sample frame in ms.
	 gauss    : Number of sample frames to be analyzed. Must be an odd number.
				Eg. 11 means 5 previous + 5 next + 1 current frame.
	 ratio    : Ratio by which the signal is changed.
	 maxgain  : Maximum gain in volume.
     minthres : Triggered if signal rises above this level.
	 
eq_enabled : Start with equalizer enabled.
dc_enabled : Start with compressor enabled.
dc_enabled : Start with normalizer enabled.
dm_enabled : Start with stereo downmix enabled.

Personal settings for reference.

preamp = -0.7
bands = {
  {freq = 2300, width = {'q', 4.0}, gain = 1.0},
  {freq = 3000, width = {'q', 4.0}, gain = -1.0},
  {freq = 4390, width = {'q', 7.0}, gain = 1.0},
  {freq = 5840, width = {'q', 4.0}, gain = -8.2},
  {freq = 7300, width = {'q', 7.0}, gain = 2.5},
  {freq = 8220, width = {'q', 5.0}, gain = -11.0},
  {freq = 10420, width = {'q', 2.0}, gain = 1.3}
}

drc = {
  knee = 3,
  ratio = 4,
  makeup = 4,
  attack = 20,
  release = 250,
  threshold = -20
}

nor = {
  gauss = 3,
  ratio = 2,
  frame = 500,
  maxgain = 0.95,
  minthres = 0
}

eq_enabled = false
dc_enabled = false
dn_enabled = false
dm_enabled = true

--]]

-- Settings --

preamp = 0
bands = {
  {freq = 64, width = {'o', 3.3}, gain = 0},   -- 20Hz - 200Hz
  {freq = 400, width = {'o', 2.0}, gain = 0},  -- 200Hz - 800Hz
  {freq = 1250, width = {'o', 1.3}, gain = 0}, -- 800Hz - 2kHz
  {freq = 2830, width = {'o', 1.0}, gain = 0}, -- 2kHz - 4kHz
  {freq = 5600, width = {'o', 1.0}, gain = 0}, -- 4kHz - 8kHz
  {freq = 12500, width = {'o', 1.3}, gain = 0} -- 8kHz - 20kHz
}

drc = {
  knee = 3,
  ratio = 4,
  makeup = 4,
  attack = 20,
  release = 250,
  threshold = -20
}

nor = {
  gauss = 3,
  ratio = 2,
  frame = 500,
  maxgain = 0.95,
  minthres = 0
}

eq_enabled = false
dc_enabled = false
dn_enabled = false
dm_enabled = true

-- Code --

local eq_tog = false
local dc_tog = false
local dn_tog = false
local dm_tog = false

local deinit_chn = -1

function check_channel()
  local c = mp.get_property_number('audio-params/channel-count')
  if not c then 
	return 0
  else
    return c
  end
end

local function push_preamp()
  if eq_tog then 
    return 'no-osd af add volume=volume=' .. preamp .. 'dB:precision=fixed'
  else
    return 'no-osd af remove volume=volume=' .. preamp .. 'dB:precision=fixed'
  end
end

local function push_eq(filter)
  if eq_tog then 
    return 'no-osd af add equalizer=f=' .. filter.freq .. ':width_type=' .. filter.width[1] .. ':w=' .. filter.width[2] .. ':g=' .. filter.gain
  else
    return 'no-osd af remove equalizer=f=' .. filter.freq .. ':width_type=' .. filter.width[1] .. ':w=' .. filter.width[2] .. ':g=' .. filter.gain
  end
end

local function push_drc()
  if dc_tog then
    return 'no-osd af add acompressor=threshold=' .. drc.threshold .. 'dB:ratio=' .. drc.ratio .. ':attack=' .. drc.attack .. ':release=' .. drc.release .. ':makeup=' .. drc.makeup .. 'dB:knee=' .. drc.knee .. 'dB'
  else
    return 'no-osd af remove acompressor=threshold=' .. drc.threshold .. 'dB:ratio=' .. drc.ratio .. ':attack=' .. drc.attack .. ':release=' .. drc.release .. ':makeup=' .. drc.makeup .. 'dB:knee=' .. drc.knee .. 'dB'
  end
end

local function push_dnm()
  if dn_tog then
    return 'no-osd af add dynaudnorm=f=' .. nor.frame .. ':g=' .. nor.gauss .. ':m=' .. nor.ratio .. ':p=' .. nor.maxgain .. ':t=' .. nor.minthres
  else
    return 'no-osd af remove dynaudnorm=f=' .. nor.frame .. ':g=' .. nor.gauss .. ':m=' .. nor.ratio .. ':p=' .. nor.maxgain .. ':t=' .. nor.minthres
  end
end

local function push_dm(chn)
  local filter
  if chn > 7 then
    filter = 'FL=0.274804*FC+0.388631*FL+0.336565*SL+0.194316*SR+0.336565*BL+0.194316*BR+0.274804*LFE|FR=0.274804*FC+0.388631*FR+0.336565*SR+0.194316*SL+0.336565*BR+0.194316*BL+0.274804*LFE'
  elseif chn == 7 then
	filter = 'FL=0.321953*FC+0.455310*FL+0.394310*SL+0.227655*SR+278819*BC+0.321953*LFE|FR=0.321953*FC+0.455310*FR+0.394310*SR+0.227655*SL+278819*BC+0.321953*LFE'
  elseif chn == 6 then
	filter = 'FL=0.374107*FC+0.529067*FL+0.458186*BL+0.264534*BR+0.374107*LFE|FR=0.374107*FC+0.529067*FR+0.458186*BR+0.264534*BL+0.374107*LFE'
  elseif chn == 5 then
	filter = 'FL=0.460186*FC+0.650802*FL+0.563611*BL+0.325401*BR|FR=0.460186*FC+0.650802*FR+0.563611*BR+0.325401*BL'
  elseif chn == 4 then
	filter = 'FL=0.422650*FL+0.366025*BL+0.211325*BR|FR=0.422650*FR+0.366025*BR+0.211325*BL'
  elseif chn == 3 then
	filter = 'FL=0.414214*FC+0.585786*FL|FR=0.414214*FC+0.585786*FR'
  else
    filter = 'FL=FL|FR=FR'
  end

  if dm_tog then 
    return 'no-osd af add pan="stereo|' .. filter .. '"'
  else
    return 'no-osd af remove pan="stereo|' .. filter .. '"'
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
  dc_tog = not dc_tog
  mp.command(push_drc())
  if dc_tog then mp.osd_message("Dynamic Compressor ON") else mp.osd_message("Dynamic Compressor OFF") end
end

local function toggle_dnm()
  dn_tog = not dn_tog
  mp.command(push_dnm())
  if dn_tog then mp.osd_message("Dynamic Normalizer ON") else mp.osd_message("Dynamic Normalizer OFF") end
end

local function toggle_eq()
  eq_tog = not eq_tog
  updateEQ()
  if eq_tog then mp.osd_message("Equalizer ON") else mp.osd_message("Equalizer OFF") end
end

local function toggle_downmix()
  local c = check_channel()
  if c > 2 then 
    dm_tog = not dm_tog
    mp.command(push_dm(c))
    if dm_tog then mp.osd_message("Downmixing " .. c .. " Channels to Stereo") else mp.osd_message("Downmixing OFF") end
  else 
    mp.osd_message("Downmixing Disabled")
  end
end

local function init_channel()
  local c = check_channel()
  if c > 0 then 
    mp.unobserve_property(init_channel)
	if c > 2 then
	  deinit_chn = c
	  dm_tog = not dm_tog
	  mp.command(push_dm(c))
	end
  end
end

local function init_filters()
  eq_tog = eq_enabled
  dc_tog = dc_enabled
  dn_tog = dn_enabled
  
  if dc_tog then mp.command(push_drc()) end
  if dn_tog then mp.command(push_dnm()) end
  if dm_enabled then mp.observe_property('audio-params/channel-count', nil, init_channel) end
  if eq_tog then updateEQ() end
end

local function deinit_filters()
  eq_tog = false
  dc_tog = false
  dn_tog = false
  dm_tog = false
  
  updateEQ()
  mp.command(push_drc())
  mp.command(push_dnm())
  mp.command(push_dm(deinit_chn))
  deinit_chn = -1
end

mp.add_key_binding('\\', "toggle-dc", toggle_drc)
mp.add_key_binding('w', "toggle-dn", toggle_dnm)
mp.add_key_binding('e', "toggle-eq", toggle_eq)
mp.add_key_binding('E', "toggle-dm", toggle_downmix)

mp.register_event("start-file", init_filters)
mp.register_event("end-file", deinit_filters)