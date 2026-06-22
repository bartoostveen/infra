{
  description = "Bart Oostveen's NixOS configurations";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.garnix.io"
      "https://attic.bartoostveen.nl/tcs-bot"
      "https://winapps.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "tcs-bot:cUYt7f0r3vvOriZybjYHTKK+jFuJPdOrPII4aXBi+1Q="
      "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-small.url = "github:nixos/nixpkgs/nixos-unstable-small"; # Generally more up-to-date kernel
    nixpkgs-stable.url = "github:nixos/nixpkgs/1cd347bf3355fce6c64ab37d3967b4a2cb4b878c"; # /nixos-25.11";
    nixpkgs-element-call.url = "github:bartoostveen/nixpkgs/element-call-0.20.0";
    nixpkgs-continuwuity.url = "github:bartoostveen/nixpkgs/continuwuity-0.5.10";
    prismlauncher-nixpkgs.url = "github:nixos/nixpkgs/077cb3aa7d111ff4d36e8bd18d906bb4a3d621f9";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik = {
      url = "github:nix-community/authentik-nix";
      # url = "github:bartoostveen/authentik-nix/authentik-2026.2.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
      };
    };

    copyparty = {
      url = "github:9001/copyparty";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    ical-proxy = {
      url = "git+https://git.bartoostveen.nl/bart/ical-proxy.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    import-tree.url = "github:vic/import-tree";

    invoice = {
      url = "github:bartoostveen/invoice";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    meowbot = {
      url = "git+ssh://forgejo@git.bartoostveen.nl/bart/meowbot.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    meshcoretomqtt = {
      url = "github:Cisien/meshcoretomqtt/2691923f90ed6d4d94407ec4a08c29b176b3a31c";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-oci-lock = {
      url = "git+ssh://forgejo@git.bartoostveen.nl/bart/nix-oci-lock.git";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixos-mailserver = {
      # url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      url = "gitlab:bartoostveen/nixos-mailserver/ldap/email";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
        git-hooks.follows = "";
      };
    };

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

    omeduostuurcentenneef-web = {
      url = "git+https://git.bartoostveen.nl/bart/omeduoweb";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        bun2nix.url = "github:nix-community/bun2nix";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    onboarding = {
      url = "git+ssh://forgejo@git.bartoostveen.nl/bart/simple-authentik-user-onboarding";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    tcs-bot = {
      url = "git+https://git.bartoostveen.nl/bart/tcs-bot";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    tlsa-exporter = {
      url = "github:ietf-tools/mail-tlsa-check-exporter";
      flake = false;
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      import-tree,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./parts);
}
