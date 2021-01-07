# mpv-scripts
A small collection of lua scripts for use in mpv player. Refer to mpv documentation on how to use a lua script in mpv.

## afilter.lua
Lua script for togglable customizable parametric equalizer and dynamic range compressor with more filter support coming in future.
```
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
bands: Add {freq = <frequency>, width = {'<type>', <value>}, gain = <gain>}, for each frequency.
       freq : Set the filter’s central frequency in Hz.
       width: Set the bandwidth of filter.
              type : Set method to specify bandwidth. (h for Hz, q for Q-Factor, o for Octave, s for Slope)
              value: Set the magnitude of the bandwidth.
       gain : Set the required gain or attenuation in dB.

preamp: Set preamp to avoid audio clipping.

drc: Enable to compress the dynamic range of audio resulting in quieter parts getting louder.
     ratio    : Ratio by which the signal is changed.
     attack   : Amount of ms the signal has to rise above the threshold before it triggers.
     release  : Amount of ms the signal has to fall below the threshold before it is restored.
     makeup   : Amount in dB the signal will be amplified after processing.
     knee     : Curve the sharp knee around threshold dB to enter gain reduction more softly. 
     threshold: Triggered if signal in dB rises above this level.
	 
eq_enabled: Start with equalizer enabled.
drc_enabled: Start with compressor enabled.
dm_enabled : Start with stereo downmix enabled.
```

## sview.lua
A simple script to show multiple shaders running, in a clean list. Triggered on shader activation or by toggle button.
