# mpv-scripts
A small collection of lua scripts for use in mpv player. Refer to mpv documentation on how to use a lua script in mpv.

## afilter.lua & equalizer.lua
These filters have been updated and combined with new whitelist system to become **aftoys.lua**. The relevant files related to afilter and equalizer can be found in `script` and `script-opts` folders respectively for legacy purpose.

## aftoys.lua
Lua script for easy access to certain audio filters in mpv. Settings are located in `aftoys.conf` in `./script-opts` folder, SOFA files are located in `./script-opts/sofa` folder and equalizer files are stored in `./script-opts/equalizer` by default.

### acompressor
Apply Dynamic Range Compression to audio, effectively compressing the range of the audio by attenuating (reducing the volume of) the louder signals and sometimes boosting the quieter signals, thereby making the overall volume level more consistent. 

**Controllable Parameters**
- `drc_ratio` - Set a ratio by which the signal is reduced. 1:2 means that if the level rose 4dB above the threshold, it will be only 2dB above after the reduction. Range is between 1 and 20.
- `drc_makeup` - Set the amount by how much signal will be amplified after processing. Range is from 1 to 64.
- `drc_knee` - Curve the sharp knee around the threshold to enter gain reduction more softly. Range is between 1 and 8.
- `drc_attack` - Amount of milliseconds the signal has to rise above the threshold before gain reduction starts. Range is between 0.01 and 2000.
- `drc_release` - Amount of milliseconds the signal has to fall below the threshold before reduction is decreased again. Range is between 0.01 and 9000.
- `drc_threshold` - If a signal of stream rises above this level in dB, it will affect the gain reduction.
- `drc_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### dynaudnorm
Applies dynamic normalization by dynamically adjusting the gain across the entire duration of the audio. Gives a more natural amplification without compressing the dynamic range of the audio, but since it samples a section of audio before and after the current time, the effect takes place gradually which gets affected if you seek abruptly to another section of video.

**Controllable Parameters**
- `dnm_frame` - Set the analyzing window frame length in milliseconds. In range from 10 to 8000 milliseconds.
- `dnm_gauss` - Set the Gaussian filter window size which is specified in frames, centered around the current frame. Should be an odd number in range from 3 to 301.
- `dnm_ratio` - Set the maximum gain factor. In range from 1.0 to 100.0.
- `dnm_peak` - Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input.
- `dnm_minthres` - Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized.
- `dnm_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### loudnorm
EBU R128 loudness normalization. Achives similar results to dynaudnorm, but more reactive to changes.

**Controllable Parameters**
- `lnm_target` - Set integrated loudness target in dB. Range is -70.0 - -5.0.
- `lnm_range` - Set loudness range target. Range is 1.0 - 50.0.
- `lnm_peak` - Set maximum true peak. Range is -9.0 - 0.0.
- `lnm_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### speechnorm
Similar to loudnorm, this filter dynamically adjust loudness by expanding or compressing each half-cycle of audio samples depending on threshold value, so audio reaches target peak value.

**Controllable Parameters**
- `snm_peak` - Set highest allowed absolute amplitude for the normalized audio input. Range is from 0.0 to 1.0.
- `snm_expand` - Set the maximum expansion factor. Allowed range is from 1.0 to 50.0.
- `snm_compress` - Set the maximum compression factor. Allowed range is from 1.0 to 50.0.
- `snm_threshold` - This option specifies which half-cycles of samples will be compressed and which will be expanded. Allowed range is from 0.0 to 1.0. 
- `snm_raise` - Set the expansion raising amount per each half-cycle of samples. Allowed range is from 0.0 to 1.0.
- `snm_fall` - Set the compression raising amount per each half-cycle of samples. Allowed range is from 0.0 to 1.0.
- `snm_invert` - When enabled any half-cycle of samples with their local peak value below or same as threshold option will be expanded otherwise it will be compressed.
- `snm_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### sofalizer
SOFAlizer uses head-related transfer functions (HRTFs) to create virtual loudspeakers around the user for binaural listening via headphones (audio formats up to 9 channels supported). The HRTFs are stored in SOFA files in the `./script-opts/sofa` folder. By default, `dodeca_and_7channel_3DSL_HRTF.sofa` is included which is the default HRTF file for VLC. 

However for better results, you can get Club Fritz SOFA files from [here](https://sofacoustics.org/data/database/clubfritz/). `ClubFritz4.sofa` will give the most neutral sound, `ClubFritz6.sofa` has a bit more bass and `ClubFritz12.sofa` has more treble.

**Controllable Parameters**
- `sfa_file` - Link to the SOFA file.
- `sfa_type` - Set processing type. Can be *time* which is processing audio in time domain (slower) or *freq* which is processing audio in frequency domain (faster).
- `sfa_gain` - Adds gain to the output audio. Avoid using it as it induces clipping and instead, use either *loudnorm* or *dynaudnorm* for increasing volume.
- `sfa_lfe` - Adds gain to the LFE channel of the audio.
- `sfa_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### equalizer
Fully customizable parametric equalizer with EQ configuration similar to EqualizerAPO format.

**Controllable Parameters**
- `eqr_preamp` - Sets the gain value in dB before equalizer parameters are set.
- `eqr_file` - Link to the equalizer file.
- `eqr_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

**Equalizer Format**
To set the equalizer, you can edit the `default.csv` file in `./script-opts/equalizer` folder. It is a comma separated value file which can be edited using text editor or any spreadsheet program. You can add new rows for adjusting each frequency. Following are the controllable parameters:

- `filter_type` - Sets the type of filter to be used. Can be *p* for parametric filter, *h* for high-shelf filter or *l* for low-shelf filter.
- `frequency` - Sets the frequency in Hz.
- `width_type` - Set method to specify band-width of filter. You can set *q* for Q-Factor, *o* for octave, *s* for slope, *h* for Hz or *k* for kHz.
- `width` - Specify the band-width of the filter in units specified by `width_type`.
- `gain` - Set the required gain or attenuation in dB.

### Media Type
The script can determine whether the media is audio or video or a movie as well as whether it has multichannel audio. Basis this, user can set whitelists for each filter. 

**Controllable Parameters**
- `vid_threshold` - Set the duration of video (in seconds) beyond which it is considered long format (movie)
- `vid_arlimit` - Set the aspect ratio of video beyond which it is considered long format (movie)
- `pre_delay` - Delays media detection and whitelist activation (in seconds). Increase this value if you feel like the script isn't detecting the media properly.

### Whitelist
Each filter can be set to auto-activate based on type of media. Currently the script is able to distinguish between audio only, short and long format video as well as whether audio is stereo or multichannel. Each media type is defined by a key as shown in table below. Multiple media types can be defined with each key separated with `|`.

Key | Media Type
--- | ---
n | No Media
a | Audio Only
s | Short Video
l | Long Video (Movie)
ma | Multichannel Audio Only
ms | Multichannel Short Video
ml | Multichannel Long Video (Movie)

For example, for audio and multichannel audio only (no video), whitelist would be `a|ma`

## sview.lua
A lightweight script that displays all loaded shaders in a clean format. It suppresses the default OSD message, allowing the custom list to be viewed by toggling it or when changing shaders.
