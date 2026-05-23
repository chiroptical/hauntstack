{ pkgs, ... }:
let
  beamPackages = with pkgs.beam28Packages; [
    erlang
    rebar3
    ex_doc
  ];
in
pkgs.mkShell {
  buildInputs =
    beamPackages
    ++ (with pkgs; [
      erlang-language-platform
      nixfmt
      treefmt
      pinact
      serve
    ]);
}
