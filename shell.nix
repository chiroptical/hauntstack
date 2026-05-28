{ pkgs, beamPackages, ... }:
let
  beamInputs = with beamPackages; [
    erlang
    rebar3
    ex_doc
    erlfmt
  ];
in
pkgs.mkShell {
  buildInputs =
    beamInputs
    ++ (with pkgs; [
      erlang-language-platform
      nixfmt
      treefmt
      serve
    ]);
}
