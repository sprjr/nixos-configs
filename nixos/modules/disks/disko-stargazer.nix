{ ... }:

{
  imports = [ ./disko-btrfs-luks.nix ];

  # Keeps the swapfile off @root: scrub, balance and snapshots all skip the block
  # groups an active swapfile occupies.
  disko.devices.disk.main.content.partitions.luks.content.content.subvolumes."@swap" = {
    mountpoint = "/swap";
    mountOptions = [ "noatime" "ssd" "discard=async" ];
  };
}
