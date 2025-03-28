{ config, pkgs, home-manager, ... }:

{
  home.file.".config/vis/colors/nord" = {
    text = ''
      gradient=true
      #2e3440
      #3b4252
      #434c5e
      #4c566a
      #d8dee9
      #e5e9f0
      #eceff4
      #8fbcbb
      #88c0d0
      #81a1c1
      #5e81ac
      #bf616a
      #d08770
      #ebcb8b
      #a3be8c
      #b48ead
    '';
  };
  home.file.".config/vis/config" = {
    text = ''
      #Refresh rate of the visualizers. A really high refresh rate may cause screen tearing. Default is 20.
      visualizer.fps=20

      #Defaults to "/tmp/mpd.fifo"
      mpd.fifo.path

      #If set to false the visualizers will use mono mode instead of stereo. Some visualizers will
      #behave differently when mono is enabled. For example, spectrum show two sets of bars.
      audio.stereo.enabled=false

      #Specifies how often the visualizer will change in seconds. 0 means do not rotate. Default is 0.
      #visualizer.rotation.secs=10

      #Configures the samples rate and the cutoff frequencies.
      audio.sampling.frequency=44100
      #audio.low.cutoff.frequency=30
      audio.low.cutoff.frequency=20
      #audio.high.cutoff.frequency=22050
      audio.high.cutoff.frequency=22050

      ##Applies scaling factor to both lorenz and ellipse visualizers. This is useful when the system audio is set
      #to a low volume.
      #visualizer.scaling.multiplier=1.5

      #Configures the visualizers and the order they are in. Available visualizers are spectrum,lorenz,ellipse.
      #Defaults to spectrum,ellipse,lorenz
      #visualizers=spectrum,ellipse,lorenz

      #Configures what character the spectrum visualizer will use. Specifying a space (e.g " ") means the
      #background will be colored instead of the character. Defaults to " ".
      #visualizer.spectrum.character=■
      #visualizer.spectrum.character=┃
      visualizer.spectrum.character=▐

      #Spectrum bar width. Defaults to 1.
      visualizer.spectrum.bar.width=1

      #The amount of space between each bar in the spectrum visualizer. Defaults to 1. It's possible to set this to
      #zero to have no space between bars
      visualizer.spectrum.bar.spacing=1

      #Available smoothing options are monstercat, sgs, none. Defaults to sgs.
      #visualizer.spectrum.smoothing.mode=monstercat

      #This configures the falloff effect on the spectrum visualizer. Available falloff options are fill,top,none.
      #Defaults to "fill"
      visualizer.spectrum.falloff.mode=none

      #Configures how fast the falloff character falls. This is an exponential falloff so values usually look
      #best 0.9+ and small changes in this value can have a large effect. Defaults to 0.95
      #visualizer.spectrum.falloff.weight=0.9

      #Margins in percent of total screen for spectrum visualizer. All margins default to 0
      visualizer.spectrum.top.margin=0.0
      visualizer.spectrum.bottom.margin=0.0
      visualizer.spectrum.right.margin=0.0
      visualizer.spectrum.left.margin=0.0

      #Reverses the direction of the spectrum so that high freqs are first and low freqs last. Defaults to false.
      visualizer.spectrum.reversed=false

      #Sets the audio sources to use. Currently available ones are "mpd" and "alsa"Sets the audio sources to use.
      #Currently available ones are "mpd", "pulse", "port", and "alsa". Defaults to "mpd".
      audio.sources=alsa

      ##vis tries to find the correct pulseaudio sink, however this will not work on all systems.
      #If pulse audio is not working with vis try switching the audio source. A list can be found by running the
      #command pacmd list-sinks  | grep -e 'name:'  -e 'index'
      audio.pulse.source=3

      #vis tries to find the correct portaudio device (through portaudio default method), however its not for-sure.
      #If port audio is not working with vis try switching the audio srouce. A list can be found by setting
      #this value to "list" and checking the vis log file. Replace this value with the device name desired
      audio.port.source=auto

      #This configures the sgs smoothing effect on the spectrum visualizer. More points spreads out the smoothing
      #effect and increasing passes runs the smoother multiple times on reach run. Defaults are points=3 and passes=2.
      visualizer.sgs.smoothing.points=3
      visualizer.sgs.smoothing.passes=2


      #Configures what character the ellipse visualizer will use. Specifying a space (e.g " ") means the
      #background will be colored instead of the character. Defaults to " ".
      #visualizer.ellipse.character=#

      #The radius of each color ring in the ellipse visualizer. Defaults to 2.
      #visualizer.ellipse.radius=2

      ## Turns off overriding the user's terminal colors
      #colors.override.terminal=false

      #Specifies the color scheme. The color scheme must be in ~/.config/vis/colors/ directory. Default is "colors"
      colors.scheme=nord
    '';
  };
}
