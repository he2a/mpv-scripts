# mpv-scripts
A small collection of lua scripts for use in mpv player. Refer to mpv documentation on how to use a lua script in mpv.

## afilter.lua
Lua script for togglable customizable parametric equalizer, audio compressor, audio normalizer and downmixer with more filter support coming in future.
```
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

drc : Enable to compress the dynamic range of audio.
	ratio    : Ratio by which the signal is changed.
	attack   : Duration in ms the signal has to rise before it triggers.
	release  : Duration in ms the signal has to fall before it is restored.
	makeup   : Amount in dB the signal will be amplified after processing.
	knee     : Curve knee around threshold to enter reduction more softly. 
	threshold: Triggered if signal in dB rises above this level.
	 
nor : Enable to dynamically normalize the loudness of audio.
	frame    : Size of audio sample frame in ms.
	gauss    : Number of sample frames to be analyzed. Must be an odd number.
		   Eg. 11 means 5 previous + 5 next + 1 current frame.
	ratio    : Ratio by which the signal is changed.
	maxgain  : Maximum gain in volume.
	minthres : Triggered if signal rises above this level.
	 
eq_enabled : Start with equalizer enabled.
dc_enabled : Start with compressor enabled.
dn_enabled : Start with normalizer enabled.
dm_enabled : Start with stereo downmix enabled.
```

## sview.lua
A simple script to show multiple shaders running, in a clean list. Triggered on shader activation or by toggle button.
