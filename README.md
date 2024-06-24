# mpv-scripts
A small collection of lua scripts for use in mpv player. Refer to mpv documentation on how to use a lua script in mpv.

## afilter.lua
Lua script for togglable customizable audio compressor and audio normalizer with more filter support coming in future. Script can be whitelisted based on whether the content is audio, video or a movie. Settings are located in `afilter.conf` in `script-opts` folder.

## equalizer.lua
Lua script for togglable parametric equalizer with EQ configuration similar to EqualizerAPO format. Script can be whitelisted based on whether the content is audio, video or a movie. Settings are located in `equalizer.conf` in `script-opts` folder, but to change the equalizer, you need to edit the `equalizer.csv` file.

## sview.lua
A simple script to show multiple shaders running, in a clean list. Triggered on shader activation or by toggle button.
