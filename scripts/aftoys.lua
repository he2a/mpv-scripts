local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local opt = require 'mp.options'

local o = {
	sfa_file = '~~/script-opts/sofa/ClubFritz6.sofa',
	sfa_type = 'time',
	sfa_gain = 10,
	sfa_lfe = 2,
	sfa_rad=1,
	
	drc_knee = 2.8,
	drc_ratio = 2,
	drc_makeup = 8,
	drc_attack = 20,
	drc_release = 250,
	drc_threshold = -20,
	
	dnm_gauss = 5,
	dnm_ratio = 4,
	dnm_frame = 400,
	dnm_peak = 0.95,
	dnm_minthres = 0,
	
	lnm_target = -16,
	lnm_range = 8,
	lnm_peak = -2,
	
	snm_peak = 0.9,
	snm_expand = 4,
	snm_compress = 2,
	snm_threshold = 0.2,
	snm_raise = 0.0001,
	snm_fall = 0.0005,
	snm_invert = 1,
	
	eqr_preamp = 0,
	eqr_file = '~~/script-opts/equalizers/default.csv',
	
	sfa_whitelist = 'ma|ms|ml',
	drc_whitelist = 'a|ma',
	dnm_whitelist = 'n',
	lnm_whitelist = 's|l',
	snm_whitelist = 'ms|ml',
	eqr_whitelist = 'l|ml',
	
	vid_threshold = 600,
	vid_arlimit = 1.2,
	pre_delay = 0.25
}

opt.read_options(o)


-- Auxilliary Functions --

local function txt2bool(txt)
	if (txt == 'yes') or (txt == 'true') then
		return true
	else
		return false
	end
end

local function parseln(line)
	local element = {}
	for value in line:gmatch("[^,]+") do
		table.insert(element, value)
	end
	return element
end

local function filechk(path)
	local file = io.open(path, 'r')
	if not file then
		mp.msg.error("Failed to load file: " .. path)
        return false
	else
        file:close()
        return true
	end
end

local function readEQFile(file_path)
	local skipFirstRow = true
	local file = io.open(file_path, 'r')
	if not file then
		return nil
	end
	local eq_array = {}

	for line in file:lines() do
		if skipFirstRow then
			skipFirstRow = false
		else
			local band = parseln(line)
			if band[4] ~= 0 then
				local entry = {
					filter_type = band[1],
					frequency = band[2],
					width_type = band[3],
					width = band[4],
					gain = band[5]
				}
				table.insert(eq_array, entry)
			end
		end
	end
	
	file:close()
	return eq_array
end

local function eq_syntax(f_type)
  if (f_type == 'p') then
    return 'equalizer'
  elseif (f_type == 'l') then
    return 'lowshelf'
  elseif (f_type == 'h') then
    return 'highshelf'
  else
    mp.msg.error("Error in eq_syntax function. Unknown argument " .. f_type .. ". Defaulting to peaking filter.")
    return 'equalizer'
  end
end

local function wlcheck(key,wl)
	if key ~= nil and wl ~= nil then
		local media_type = '|' .. key .. '|'
		local media_whtl = '|' .. wl .. '|'
		return string.find(media_whtl, media_type, 1, true) ~= nil
	end
end

-- Main Functions --

local drc_filter = { active = false, syntax = 'acompressor=threshold=' .. o.drc_threshold .. 'dB:ratio=' .. o.drc_ratio .. ':attack=' .. o.drc_attack .. ':release=' .. o.drc_release .. ':makeup=' .. o.drc_makeup .. 'dB:knee=' .. o.drc_knee .. 'dB' }
local dnm_filter = { active = false, syntax = 'dynaudnorm=f=' .. o.dnm_frame .. ':g=' .. o.dnm_gauss .. ':m=' .. o.dnm_ratio .. ':p=' .. o.dnm_peak .. ':t=' .. o.dnm_minthres }
local snm_filter = { active = false, syntax = 'speechnorm=p=' .. o.snm_peak .. ':e=' .. o.snm_expand .. ':c=' .. o.snm_compress .. ':t=' .. o.snm_threshold .. ':r=' .. o.snm_raise .. ':f=' .. o.snm_fall .. ':i=' .. o.snm_invert }
local lnm_filter = { active = false, syntax = 'loudnorm=i=' .. o.lnm_target .. ':lra=' .. o.lnm_range .. ':tp=' .. o.lnm_peak }
local sfa_filter = { active = false, enabled = filechk(mp.command_native({"expand-path", o.sfa_file})), syntax = 'sofalizer=sofa="' .. mp.command_native({"expand-path", o.sfa_file}) .. '":type='.. o.sfa_type .. ':radius=' .. o.sfa_rad .. ':gain=' .. o.sfa_gain .. ':lfegain=' .. o.sfa_lfe }
local eqr_filter = { active = false, enabled = filechk(mp.command_native({"expand-path", o.eqr_file})), syntax = 'volume=volume=' .. o.eqr_preamp .. 'dB:precision=fixed', bands = readEQFile(mp.command_native({"expand-path", o.eqr_file})) }

local function push_filter(filter)
	if filter.active then
		return 'no-osd af add ' .. filter.syntax
	else
		return 'no-osd af remove ' .. filter.syntax
	end
end

local function push_eq()
	if eqr_filter.enabled and eqr_filter.bands then
		for i = 1, #eqr_filter.bands do
			local f = eqr_filter.bands[i]
			if f.gain ~= 0 then
				if eqr_filter.active then 
					mp.command('no-osd af add ' .. eq_syntax(f.filter_type) .. '=f=' .. f.frequency .. ':t=' .. f.width_type .. ':w=' .. f.width .. ':g=' .. f.gain)
				else
					mp.command('no-osd af remove ' .. eq_syntax(f.filter_type) .. '=f=' .. f.frequency .. ':t=' .. f.width_type .. ':w=' .. f.width .. ':g=' .. f.gain)
				end
			end
		end
	end
end

local function toggle_drc(flag)
	drc_filter.active = not drc_filter.active
	mp.command(push_filter(drc_filter))
	if flag ~= 1 then 
		if drc_filter.active then 
			mp.osd_message("Dynamic Range Compressor ON")
		else
			mp.osd_message("Dynamic Range Compressor OFF") 
		end
	end
end

local function toggle_dnm(flag)
	dnm_filter.active = not dnm_filter.active
	mp.command(push_filter(dnm_filter))
	if flag ~= 1 then 
		if dnm_filter.active then 
			mp.osd_message("Dynamic Audio Normalizer ON") 
		else 
			mp.osd_message("Dynamic Normalizer OFF") 
		end
	end
end

local function toggle_snm(flag)
	snm_filter.active = not snm_filter.active
	mp.command(push_filter(snm_filter))
	if flag ~= 1 then 
		if snm_filter.active then
			mp.osd_message("Speech Normalizer ON")
		else
			mp.osd_message("Speech Normalizer OFF")
		end
	end
end

local function toggle_lnm(flag)
	lnm_filter.active = not lnm_filter.active
	mp.command(push_filter(lnm_filter))
	if flag ~= 1 then 
		if lnm_filter.active then
			mp.osd_message("Loudness Normalizer ON")
		else
			mp.osd_message("Loudness Normalizer OFF")
		end
	end
end

local function toggle_sfa(flag)
	sfa_filter.active = not sfa_filter.active
	mp.command(push_filter(sfa_filter))
	if flag ~= 1 then 
		if sfa_filter.active then
			mp.osd_message("Sofalizer ON")
		else
			mp.osd_message("Sofalizer OFF")
		end
	end
end

local function toggle_eqr(flag)
	eqr_filter.active = not eqr_filter.active
	
	if (o.eqr_preamp < 0 or o.eqr_preamp > 0) then 
		mp.command(push_filter(eqr_filter))
	end
	
	push_eq()
	
	if flag ~= 1 then 
		if eqr_filter.active then
			mp.osd_message("Equalizer ON")
		else
			mp.osd_message("Equalizer OFF")
		end
	end
end

local function mdcheck()
	local aid = mp.get_property_native("aid") or false
	local mkey = ''
	
	if not aid then
		mkey = 'n'
	else	
		local ch = mp.get_property_native("audio-params/channel-count") or 2
		local vid = mp.get_property_native("vid") or false
		local fps = mp.get_property_native("estimated-vf-fps") or 0
		local ar = mp.get_property_native("video-params/aspect") or 0
		local tt = mp.get_property_native("duration") or 0
		local vt = o.vid_threshold
		local vr = o.vid_arlimit
		
		if not vid or (fps <= 1) then
			mkey = 'a'
		elseif (ar >= vr) and (tt >= vt) then
			mkey = 'l'
		elseif (tt < vt) then
			mkey = 's'
		else
			mkey = 'n'
		end
		
		if (ch > 2) then
			mkey = 'm' .. mkey
		end
	end
	return mkey or 'n'
end

-- Script init --

local first_run  = true

local function init()
	if first_run then
		mp.command('no-osd af clr ""')
		first_run = false
	else
		if drc_filter.active then 
			drc_filter.active = false
			mp.command(push_filter(drc_filter))
		end
		if dnm_filter.active then 
			dnm_filter.active = false
			mp.command(push_filter(dnm_filter))
		end
		if snm_filter.active then 
			snm_filter.active = false
			mp.command(push_filter(snm_filter))
		end
		if lnm_filter.active then 
			lnm_filter.active = false
			mp.command(push_filter(lnm_filter))
		end
		if sfa_filter.enabled and sfa_filter.active then 
			sfa_filter.active = false
			mp.command(push_filter(sfa_filter))
		end
		if eqr_filter.enabled and eqr_filter.active then 
			eqr_filter.active = false
			if (o.eqr_preamp < 0 or o.eqr_preamp > 0) then 
				mp.command(push_filter(eqr_filter))
			end
			push_eq()
		end
	end
	
	-- Deinit complete
		
	med_type = mdcheck()
	-- mp.msg.info("Media type:" .. med_type)
	if med_type ~= 'n' then
		if wlcheck(med_type,o.sfa_whitelist) then toggle_sfa(1) end
		if wlcheck(med_type,o.snm_whitelist) then toggle_snm(1) end
		if wlcheck(med_type,o.lnm_whitelist) then toggle_lnm(1) end
		if wlcheck(med_type,o.dnm_whitelist) then toggle_dnm(1) end
		if wlcheck(med_type,o.drc_whitelist) then toggle_drc(1) end
		if wlcheck(med_type,o.eqr_whitelist) then toggle_eqr(1) end
	end
	-- mp.msg.info("AF-Toys Init complete.")
end

mp.add_key_binding('c', "toggle-drc", toggle_drc)
mp.add_key_binding('n', "toggle-snm", toggle_snm)
mp.add_key_binding('l', "toggle-lnm", toggle_lnm)
mp.add_key_binding('d', "toggle-dnm", toggle_dnm)
mp.add_key_binding('S', "toggle-sfa", toggle_sfa)
mp.add_key_binding('E', "toggle-eqr", toggle_eqr)

mp.register_event("file-loaded", 
	function()
		delay = mp.add_timeout(o.pre_delay,
			function()
				init()
				delay:kill()
				delay = nil
			end
		)
	end
)