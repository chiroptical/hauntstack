{
  pkgs,
  beamPackages,
  src,
}:
let
  # Bundle plugins so rebar3 doesn't try to fetch them from the network.
  # rebar3_ex_doc isn't in nixpkgs yet; eunit/ct will warn about it.
  rebar3WithPlugins = beamPackages.rebar3WithPlugins {
    plugins = with beamPackages; [ erlfmt ];
  };

  # Copy our source code into the temporary directory where our checks will
  # take place.
  copySource = ''
    cp -r ${src} hauntstack
    chmod -R +w hauntstack
    cd hauntstack
    export HOME=$TMPDIR
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
          rebar3WithPlugins
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
          rebar3WithPlugins
        ];
      }
      ''
        ${copySource}
        rebar3 ct
        touch $out
      '';
}
