# mpv-scripts
A small collection of lua scripts for use in mpv player. Refer to mpv documentation on how to use a lua script in mpv.

## afilter.lua
Lua script for easy access to certain audio filters in mpv. Settings are located in `afilter.conf` in `./script-opts` folder and the SOFA files are located in `./script-opts/sofa` folder.

### acompressor
Apply Dynamic Range Compression to audio, effectively compressing the range of the audio by attenuating (reducing the volume of) the louder signals and sometimes boosting the quieter signals, thereby making the overall volume level more consistent. Good for music but can lead to a loss of dynamic contrast, making the audio sound squashed or lifeless, especially for movies.

**Controllable Parameters**
- `drc_enabled` - Keeps the filter enabled at launch of file (subject to whitelist parameter).
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
- `dnm_enabled` - Keeps the filter enabled at launch of file (subject to whitelist parameter).
- `dnm_frame` - Set the analyzing window frame length in milliseconds. In range from 10 to 8000 milliseconds.
- `dnm_gauss` - Set the Gaussian filter window size which is specified in frames, centered around the current frame. Should be an odd number in range from 3 to 301.
- `dnm_ratio` - Set the maximum gain factor. In range from 1.0 to 100.0.
- `dnm_peak` - Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input.
- `dnm_minthres` - Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized.
- `dnm_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### loudnorm
EBU R128 loudness normalization. Achives similar results to dynaudnorm, but more reactive to changes.

**Controllable Parameters**
- `lnm_enabled` - Keeps the filter enabled at launch of file (subject to whitelist parameter).
- `lnm_target` - Set integrated loudness target in dB. Range is -70.0 - -5.0.
- `lnm_range` - Set loudness range target. Range is 1.0 - 50.0.
- `lnm_peak` - Set maximum true peak. Range is -9.0 - 0.0.
- `lnm_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### sofalizer
SOFAlizer uses head-related transfer functions (HRTFs) to create virtual loudspeakers around the user for binaural listening via headphones (audio formats up to 9 channels supported). The HRTFs are stored in SOFA files in the `./script-opts/sofa` folder. By default, `dodeca_and_7channel_3DSL_HRTF.sofa` is included which is the default HRTF file for VLC. 

However for better results, you can get Club Fritz SOFA files from [here](https://sofacoustics.org/data/database/clubfritz/). `ClubFritz4.sofa` will give the most neutral sound, `ClubFritz6.sofa` has a bit more bass and `ClubFritz12.sofa` has more treble.

**Controllable Parameters**
- `sofa_enabled` - Keeps the filter enabled at launch of file (subject to whitelist parameter).
- `sofa_file` - Link to the SOFA file.
- `sofa_type` - Set processing type. Can be *time* which is processing audio in time domain (slower) or *freq* which is processing audio in frequency domain (faster).
- `sofa_gain` - Adds gain to the output audio. Avoid using it as it induces clipping and instead, use either *loudnorm* or *dynaudnorm* for increasing volume.
- `sofa_lfe` - Adds gain to the LFE channel of the audio.
- `sofa_whitelist` - Sets whitelists for the filter. See the *Whitelist* section for more details.

### Other settings
- `vid_threshold` - Sets the length of the video beyond which it can be considered as a movie. Value is in seconds.
- `vid_arlimit` - Sets the aspect ratio of the video beyond which it can be considered as a movie.
- `*_whitelist` - Whitelists the filters to be applied only at certain conditions. Can be set to one of the following values.
  - `audio` - For audio files.
  - `audmc` - For multichannel audio files.
  - `video` - For videos below threshold length and aspect ratio.
  - `vidmc` - Same as above, but for ones with multichannel sound.
  - `movie` - For videos above threshold length and aspect ratio.
  - `movmc` - Same as above, but for ones with multichannel sound.
  - `allav` - Applies to all files.
  - `allmc` - Applies to all multichannel audio sources.

## equalizer.lua
Lua script for togglable parametric equalizer with EQ configuration similar to EqualizerAPO format. Script can be whitelisted based on whether the content is audio, video or a movie. Settings are located in `equalizer.conf` in `./script-opts` folder, but to change the equalizer configuration, you need to edit the `default.csv` file in `./script-opts/equalizer` folder.

### Script Settings
To change the script settings, you can edit the `equalizer.conf` file in `./script-opts` folder.

**Controllable Parameters**
- `preamp` - Sets the gain value in dB before equalizer parameters are set.
- `eqr_enabled` - Keeps the equalizer enabled at launch of file (subject to whitelist parameter).
- `eqr_whitelist` - Whitelists the equalizer to be applied only at certain conditions. Can be set to one of the following values.
  - `audio` - Activates in case of audio file.
  - `video` - Activates in case of all video files (with audio obviously)
  - `movie` - Activates in case of video files with certain restrictions that can be controlled by `vid_threshold` and `vid_arlimit` parameters.
  - `allav` - Applies to all files.
- `vid_threshold` - Sets the length of the video beyond which it can be considered as a movie. Value is in seconds.
- `vid_arlimit` - Sets the aspect ratio of the video beyond which it can be considered as a movie.
- `eqr_file` - Link to the equalizer file.

### Equalizer Settings
To set the equalizer, you can edit the `default.csv` file in `./script-opts/equalizer` folder. It is a comma separated value file which can be edited using text editor or any spreadsheet program. You can add new rows for adjusting each frequency.

**Controllable Parameters**
- `filter_type` - Sets the type of filter to be used. Can be *p* for parametric filter, *h* for high-shelf filter or *l* for low-shelf filter.
- `frequency` - Sets the frequency in Hz.
- `width_type` - Set method to specify band-width of filter. You can set *q* for Q-Factor, *o* for octave, *s* for slope, *h* for Hz or *k* for kHz.
- `width` - Specify the band-width of the filter in width_type units.
- `gain` - Set the required gain or attenuation in dB.

## sview.lua
A lightweight script that displays all loaded shaders in a clean format. It suppresses the default OSD message, allowing the custom list to be viewed by toggling it or when changing shaders.
