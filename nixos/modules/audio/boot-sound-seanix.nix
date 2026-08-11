{ ... }:

{
  imports = [
    ./boot-sound.nix
  ];

  services.boot-sound = {
    enable = true;
    device = "plughw:CARD=NVidia,DEV=7";
    soundFile = ../../share/sounds/mac-boot-chime.wav;
  };
}
