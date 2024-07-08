{ config, pkgs, ... }:

{
  boot.enableVirtualMachines = true;

  virtualMachines.guest = {
    autoStart = true;

    config = {
      system.stateVersion = "19.03";
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keyFiles = [
        /root/.ssh/authorized_keys
      ];
    };

    qemuSwitches = [
      "nic user,hostfwd=tcp::10022-:22"
    ];
  };
}
