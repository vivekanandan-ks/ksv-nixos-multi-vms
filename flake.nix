{
  description = "Multiple NixOS VMs with SSH access";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    k0s-flake.url = "github:vivekanandan-ks/ksv-k0s-nix-package";
  };

  outputs = { self, nixpkgs, k0s-flake }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Define a function to create each VM
      createVM = vmName: hport: gport: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, ... }: {
            imports = [ "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix" ];

            networking.hostName = vmName;
            networking.firewall.enable = false;

            services.openssh.enable = true;
            services.openssh.settings.PermitRootLogin = "yes";
            users.users.root = {
              isNormalUser = false;
              hashedPassword = "$6$IuOZIMCx7ZwxSygV$xolfZMDt1h3mtxlzTuBdLqeW2BnkSo12c4yyy.Skt2qlOpJAPxZmYw1XlRE1wqluv0imrPKbRuKRuN78LJRrn0";
            };

            virtualisation.forwardPorts = [
              {
                from = "host";
                host.port = hport;
                guest.port = gport;
              }
            ];

            environment.systemPackages = with pkgs; [ 
              btop
              k0s-flake.packages.${system}.default
              ];
            system.stateVersion = "24.11";
          })
        ];
      };
    in
    {
      # NixOS configurations
      nixosConfigurations = {
        vm1 = createVM "vm1" 2222 2222;
        vm2 = createVM "vm2" 3333 3333;
        vm3 = createVM "vm3" 4444 4444;
      };
      
      # Expose the VMs as buildable packages
      packages.${system} = {
        vm1 = self.nixosConfigurations.vm1.config.system.build.vm;
        vm2 = self.nixosConfigurations.vm2.config.system.build.vm;
        vm3 = self.nixosConfigurations.vm3.config.system.build.vm;
        default = self.nixosConfigurations.vm1.config.system.build.vm;
      };
    };
}