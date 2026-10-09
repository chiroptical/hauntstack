{
  lib,
  stdenv,
  erlang,
  writableTmpDirAsHomeHook,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "rebar3";
  version = "4.0.0-rc2";

  src = fetchFromGitHub {
    owner = "stritzinger";
    repo = "rebar3";
    tag = "4.0.0-rc2";
    hash = "sha256-lJH/t+jr349KTpYcL6Dy4Z+MV908X7zqhNychzQO74Q=";
  };

  nativeBuildInputs = [
    erlang
    writableTmpDirAsHomeHook
  ];

  buildInputs = [ erlang ];

  buildPhase = ''
    runHook preBuild

    escript bootstrap

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    sed -i 's/%%! +sbtu +A1/%%! +sbtu +A1 -escript main rebar/' _build/prod/bin/rebar
    mkdir -p $out/bin
    cp _build/prod/bin/rebar $out/bin/rebar3

    runHook postInstall
  '';

  doCheck = false;

  meta = {
    homepage = "https://github.com/stritzinger/rebar3";
    description = "Erlang build tool that makes it easy to compile and test Erlang applications, port drivers and releases";
    mainProgram = "rebar3";
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
  };
}
