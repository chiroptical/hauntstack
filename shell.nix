{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    erlang
    rebar3
    erlang-language-platform
    nixfmt
    treefmt
    pinact
  ];
}
