{
  description = "hauntstack";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            beamPackages = pkgs.beam28Packages;
          in
          function { inherit pkgs beamPackages; }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs, beamPackages }:
        {
          default = pkgs.callPackage ./shell.nix { inherit beamPackages; };
        }
      );

      checks = forAllSystems (
        { pkgs, beamPackages }:
        import ./checks.nix {
          inherit pkgs beamPackages;
          src = self;
        }
      );
    };
}
