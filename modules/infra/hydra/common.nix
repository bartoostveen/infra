{
  nix.settings = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "hydra-queue-builder"
      "build"
      "root"
    ];
    builders-use-substitutes = true;
  };
}
