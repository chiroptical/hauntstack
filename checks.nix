{
  pkgs,
  beamPackages,
  src,
}:
let
  # Bundle deps and plugins as _checkouts so rebar3 doesn't try to fetch them
  # from the network.
  hexDeps = [
    (import ./nix/s2.nix { inherit beamPackages; })
    (import ./nix/rebar3_ex_doc.nix { inherit beamPackages; })
  ];

  # Copy our source code into the temporary directory where our checks will
  # take place.
  copySource = ''
    cp -r ${src} hauntstack
    chmod -R +w hauntstack
    cd hauntstack
    export HOME=$TMPDIR

    # Set up Hex dependencies and plugins as _checkouts/
    mkdir -p _checkouts
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      cp -r ${dep} _checkouts/${dep.pname}
    '') hexDeps}
    chmod -R +w _checkouts/
  '';
in
{
  treefmt =
    pkgs.runCommand "Check formatting"
      {
        nativeBuildInputs = [
          pkgs.treefmt
          pkgs.nixfmt
          beamPackages.erlfmt
        ];
      }
      ''
        ${copySource}
        treefmt --ci --walk filesystem
        touch $out
      '';

  eunit =
    pkgs.runCommand "Run rebar3 eunit"
      {
        nativeBuildInputs = [
          beamPackages.erlang
          beamPackages.rebar3
        ];
      }
      ''
        ${copySource}
        rebar3 eunit
        touch $out
      '';

  ct =
    pkgs.runCommand "Run rebar3 ct"
      {
        nativeBuildInputs = [
          beamPackages.erlang
          beamPackages.rebar3
        ];
      }
      ''
        ${copySource}
        rebar3 ct
        touch $out
      '';
}
